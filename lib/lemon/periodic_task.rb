#-*- encoding: utf-8 -*-
#
# This file is part of the Lemon Network Monitor.
# Copyright (C) 2011, Tobias Koch <tobias@tobijk.de>
#
# Lemon is licensed under the GNU General Public License, version 2. A copy of
# the license text can be found in the file LICENSE in the source distribution.
#

require 'lemon/error'
require 'lemon/check'
require 'subprocess'

module Lemon

  class PeriodicTask
    include Subprocess

    attr_reader :next_update, :last_update, :result, :message, :description

    def initialize(config = {})
      @next_update = Time.now
      @last_update = nil
      @result = Lemon::Check::WAIT
      @update_interval = config['update_interval'].to_i
      @description = config['description'] || ""

      begin
        @check = Lemon.const_get("#{config['name'].capitalize}Check").new
      rescue NameError
        raise Lemon::Error, "failed to load check '#{config['name']}'"
      end

      @params = config['params']

      @buffer = ""
      @active = false
    end

    def active?
      @active
    end

    def started
      @buffer = ""
      @active = true
    end

    def stopped
      @active = false
    end

    def run
      # reset the command line
      ARGV.clear

      # place positional arguments
      i = 0
      @params.each_pair do |key, value|
        next if key.nil?

        key = key.gsub(/_/, '-')

        if value.is_a? Array
          value.each do |v|
            ARGV[i] = "--#{key}=#{v}"
            i += 1
          end
        else
          ARGV[i] = "--#{key}=#{value}"
          i += 1
        end
      end

      # put plain arguments at the end
      case @params[nil]
        when String
          ARGV[i] = @params[nil]
          i += 1
        when Array
          @params[nil].each do |arg|
            ARGV[i] = arg
            i += 1
          end
      end

      # run the check
      @check.run_check()
    end

    def update
      begin
        while true
          buf = @stdeo.read_nonblock(1024)
          @buffer << buf if !buf.empty? or break
        end
      rescue EOFError
        @message, @buffer = @buffer, ""
        @result = wait()
        @last_update = Time.now
        @next_update = @last_update + @update_interval
      rescue Exception
        # ignore
      end
    end

  end

end
