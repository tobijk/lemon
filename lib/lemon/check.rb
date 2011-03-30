#-*- encoding: utf-8 -*-
#
# This file is part of the Lemon Network Monitor.
# Copyright (C) 2011, Tobias Koch <tobias@tobijk.de>
#
# Lemon is licensed under the GNU General Public License, version 2. A copy of
# the license text can be found in the file LICENSE in the source distribution.
#

require 'lemon/error'

module Lemon

  class Check

    PASS = 0
    WARN = 1
    FAIL = 2
    WAIT = 3

    class Error < Lemon::Error
    end

    def timeout(seconds = nil, &block)
      unless seconds.nil?
        Timeout.timeout(seconds, block)
      else
        yield
      end
    end

    def run_check
      begin
        parse_command_line
        execute
      rescue Lemon::Check::Error => e
        $stderr.write "#{e.message}\n"
        return FAIL
      end
    end

    def time_execution
      time0 = Time.now
      yield
      time1 = Time.now
      return time1 - time0
    end

  end

end
