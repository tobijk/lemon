#-*- encoding: utf-8 -*-
#
# This file is part of the Lemon Network Monitor.
# Copyright (C) 2011, Tobias Koch <tobias@tobijk.de>
#
# Lemon is licensed under the GNU General Public License, version 2. A copy of
# the license text can be found in the file LICENSE in the source distribution.
#

require 'lemon/periodic_task'
require 'lemon/check'
require 'lemon/logger'

module Lemon

  class Scheduler

    def initialize(globals, tasks)
      @config = globals
      @tasks = tasks
      @stop = false
      @thread = nil
    end

    def run
      @thread = Thread.new do
        work
      end
    end

    def join
      @thread.join if @thread
    end

    # This needs to be rewritten:
    #
    # * it's missing any sort of rate limiting,
    #
    # * it should be made event-driven using 'select' or 'poll'
    #   on the local pipe ends of the tasks
    #
    def work
      status_to_string = {
        Lemon::Check::PASS => "[  OK  ]",
        Lemon::Check::WARN => "[ WARN ]",
        Lemon::Check::FAIL => "[ FAIL ]"
      }

      while !@stop
        active_tasks.each do |t|
          t.update
          if t.finished?
            msg = "#{status_to_string[t.exit_code]} #{t.description} - "\
                  "#{t.message.split(/(?:\r|\n)+/)[0]}"
            Lemon::Logger.write(msg)
          end
        end

        now = Time.now
        waiting_tasks.each do |t|
          if t.next_update < now
            t.spawn
          end
        end

        sleep 1
      end

      # terminate all active checks the hard way
      active_tasks.each do |t|
        t.kill "KILL"
        t.wait
      end
    end

    def stop!
      @stop = true
    end

    def active_tasks
      @tasks.select { |t| t.active?  }
    end

    def waiting_tasks
      @tasks.select { |t| !t.active? }
    end

  end

end
