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

    attr_reader :next_update, :last_update, :result, :message

    def initialize(config = {})
      @next_update = Time.now
      @last_update = nil
      @result = Lemon::Check::WAIT
      @update_interval = config['update_interval']

      begin
        @check = Kernel.const_get("Lemon#{config['name'].capitalize}Check").new
      rescue NameError
        raise Lemon::Error, "failed to load command module '#{config['name']}'"
      end

      @params = config['params']
      @buffer = ""
    end

    def started
      io_nonblock = true
      @buffer = ""
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
      @check.run_check
    end

    def update
      @buffer << @stdeo.read unless @stdeo.eof?
      if finished?
        @message = @buffer
        @result = exit_code
        @last_update = Time.now
        @next_update = @last_update + @update_interval
      end
    end

  end

end
