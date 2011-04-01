#-*- encoding: utf-8 -*-
#
# This file is part of the Lemon Network Monitor.
# Copyright (C) 2011, Tobias Koch <tobias@tobijk.de>
#
# Lemon is licensed under the GNU General Public License, version 2. A copy of
# the license text can be found in the file LICENSE in the source distribution.
#

require 'lemon/check'
require 'openssl'
require 'net/http'
require 'net/https'
require 'uri'
require 'getoptlong'

class LemonHttpCheck < Lemon::Check

  def usage
    "Lemon Network Monitor - HTTP Check                                              \n"\
    "Copyright (C) 2011 Tobias Koch <tobias@tobijk.de>                               \n"\
    "                                                                                \n"\
    "USAGE: lemon http [OPTIONS] <url>                                               \n"\
    "                                                                                \n"\
    "OPTIONS:                                                                        \n"\
    "                                                                                \n"\
    "-e, --content-check=<regex>     verify that document contains regex, this       \n"\
    "                                option can be specified multiple times          \n"\
    "--connect-timeout=<integer>     number of seconds for connection timeout        \n"\
    "--request-timeout=<integer>     number of seconds for HTTP request timeout      \n"\
    "--allow-redirect                allow redirection, otherwise treated as error   \n"\
    "                                                                                \n"
  end

  def parse_command_line
    @config = {
      'allow_redirect' => false,
      'content_check'  => []
    }

    opts = GetoptLong.new(
      [ '--help', '-h',          GetoptLong::NO_ARGUMENT ],
      [ '--content-check', '-e', GetoptLong::REQUIRED_ARGUMENT ],
      [ '--connect-timeout',     GetoptLong::REQUIRED_ARGUMENT ],
      [ '--request-timeout',     GetoptLong::REQUIRED_ARGUMENT ],
      [ '--allow-redirect',      GetoptLong::NO_ARGUMENT ]
    )

    opts.quiet = true
    begin
      opts.each do |opt, arg|
        case opt
          when '--help'
            puts usage
            exit 0
          when '--content-check'
            @config['content_check'].push /#{arg}/
          when '--connect-timeout'
            @config['connect_timeout'] = arg.to_i
          when '--request-timeout'
            @config['request_timeout'] = arg.to_i
          when '--allow-redirect'
            @config['allow_redirect'] = true
        end
      end
    rescue GetoptLong::Error => e
      raise Lemon::Check::Error, e.message
    end

    unless ARGV.size > 0
      raise Lemon::Check::Error, "No URL specified"
    end

    begin
      @url = URI.parse(ARGV[0])
    rescue Exception => e
      raise Lemon::Check::Error, e.message
    end

    unless [ URI::HTTP, URI::HTTPS ].include? @url.class
      raise Lemon::Check::Error, "Invalid or missing URL scheme in '#{ARGV[0]}'"
    end
  end

  def execute
    begin
      connect_time, request_time, response_body = fetch(@url)
    rescue Exception => e
      raise Lemon::Check::Error, e.message
    end

    verdict(connect_time, request_time, response_body)
  end

  private

  def fetch(url, redirect_depth = 0)
    if redirect_depth > 5
      msg = "Server seems to be stuck in redirect loop?"
      raise Lemon::Check::Error, msg
    end

    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true if url.scheme == "https"
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    http.open_timeout = @config['connect_timeout'] if @config['connect_timeout']
    http.read_timeout = @config['request_timeout'] if @config['request_timeout']

    # establish connection
    begin
      connect_time = time_execution { http.start }
    rescue Timeout::Error
      msg = "Timeout occurred while opening connection"
      raise Lemon::Check::Error, msg
    ensure
      begin http.finish() rescue IOError ; end
    end

    response = nil

    # do HTTP request
    begin
      path = url.path.empty? ? '/' : url.path
      request_time = time_execution { response = http.get(path) }
    rescue Timeout::Error
      msg = "Timeout occurred while reading response"
      raise Lemon::Check::Error, msg
    ensure
      begin http.finish() rescue IOError ; end
    end

    response_body = response.body

    # handle redirection and errors
    if Net::HTTPRedirection === response && @config['allow_redirect']
      url = URI.parse(response['location'])
      connect_time, request_time, response_body = fetch(url, redirect_depth + 1)
    else
      unless Net::HTTPSuccess === response
        msg = "HTTP request failed with status #{response.code} - #{response.class}"
        raise Lemon::Check::Error, msg
      end
    end

    return connect_time, request_time, response_body
  end

  def verdict(connect_time, request_time, document)
    state = Lemon::Check::PASS

    msg = "Established connection in %dms and completed HTTP request in %dms.\n"\
      % [ connect_time * 1000, request_time * 1000 ]

    @config['content_check'].each do |regex|
      unless document =~ regex
        state = Lemon::Check::FAIL
        msg   = "Content check /#{regex.source}/ failed\n\n#{msg}"
        break
      end
    end

    $stdout.write(msg)
    return state
  end

end

