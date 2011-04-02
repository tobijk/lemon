#-*- encoding: utf-8 -*-
#
# This file is part of the Lemon Network Monitor.
# Copyright (C) 2011, Tobias Koch <tobias@tobijk.de>
#
# Lemon is licensed under the GNU General Public License, version 2. A copy of
# the license text can be found in the file LICENSE in the source distribution.
#

require 'lemon/config'
require 'lemon/error'
require 'lemon/version'
require 'lemon/scheduler'
require 'lemon/logger'
require 'lemon/constants'
require 'getoptlong'

module Lemon

  class Daemon

    def initialize
      @subsystems = []
    end

    def usage
      puts "Lemon Network Monitor, version #{LEMON_VERSION}                           \n"
      puts "Copyright (C) 2011, Tobias Koch <tobias@tobijk.de>                        \n"
      puts "                                                                          \n"
      puts "USAGE: lemond [OPTIONS]                                                   \n"
      puts "                                                                          \n"
      puts "OPTIONS:                                                                  \n"
      puts "                                                                          \n"
      puts "--help, -h         print this help message                                \n"
      puts "--daemonize        fork into background                                   \n"
      puts "--pid-file=<file>  write pidfile when run as daemon                       \n"
      puts "--log-file=<file>  override log file location                             \n"
      puts "                                                                          \n"
    end

    def load_plugins
      PLUGIN_SEARCH_PATH.each do |dir|
        Dir.glob(dir + '/*.rb').each do |plugin|
          load plugin
        end
      end
    end

    def daemonize
      pid_file = @config['pid_file']

      if pid = fork
        File.open(pid_file, "w") { |f| f.write "#{pid}" } if pid_file
        [ $stdin, $stdout, $stderr ].each { |io| io.close }
        exit! 0
      end
      Process.setpgrp 
    end

    def parse_command_line
      config = {}

      opts = GetoptLong.new(
        [ '--help', '-h', GetoptLong::NO_ARGUMENT ],
        [ '--daemonize',  GetoptLong::NO_ARGUMENT ],
        [ '--pid-file',   GetoptLong::REQUIRED_ARGUMENT ],
        [ '--log-file',   GetoptLong::REQUIRED_ARGUMENT ]
      )

      opts.quiet = true
      begin
        opts.each do |opt, arg|
          case opt
            when '--help'
              usage
              exit 0
            when '--daemonize'
              config['daemonize'] = true
            when '--pid-file'
              config['pid_file'] = arg
            when '--log-file'
              config['log_file'] = arg
          end
        end
      rescue GetoptLong::Error => e
        raise Lemon::Error, e.message
      end

      return config
    end

    def read_config
      defaults = {
        'daemonize' => false,
        'update_interval' => 300,
        'log_file' => LOG_FILE,
        'pid_file' => PID_FILE
      }

      config = nil

      CONFIG_SEARCH_PATH.each do |config_file|
        if File.exist? config_file
          config = Lemon::Config.new(config_file) if File.exist? config_file
          break
        end
      end

      # merge with defaults, but don't override
      config.global_conf.merge!(defaults) { |k,o,n| o }

      # command line overrides config file
      config.global_conf.merge!(parse_command_line)

      @config = config
    end

    def execute
      load_plugins
      config = read_config
      Lemon::Logger.instance(config.global_conf['log_file'])

      daemonize(config.global_conf['pid_file'])\
        if config.global_conf['daemonize']

      tasks = config.hosts.collect { |h| h.tasks }.flatten
      scheduler = Lemon::Scheduler.new(config.global_conf, tasks)
      scheduler.run

      @subsystems << scheduler
      @subsystems.each { |sub| sub.join }

      Lemon::Logger.close
    end

    def stop!
      @subsystems.each { |sub| sub.stop! }
    end

  end

end

