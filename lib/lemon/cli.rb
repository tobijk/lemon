#-*- encoding: utf-8 -*-
#
# This file is part of the Lemon Network Monitor.
# Copyright (C) 2011, Tobias Koch <tobias@tobijk.de>
#
# Lemon is licensed under the GNU General Public License, version 2. A copy of
# the license text can be found in the file LICENSE in the source distribution.
#

require 'lemon/version'
require 'lemon/constants'

module Lemon

  class CLI

    def initialize
      load_command_list
    end

    def usage
      puts "Lemon Network Monitor CLI, version #{LEMON_VERSION}                     \n"
      puts "Copyright (C) 2011, Tobias Koch <tobias@tobijk.de>                      \n"
      puts "                                                                        \n"
      puts "USAGE: lemon <command> [OPTIONS] <...>                                  \n"
      puts "                                                                        \n"
      puts "AVAILABLE COMMANDS:                                                     \n"
      puts "                                                                        \n"

      @commands.each do |command|
        puts " #{command}\n"
      end

      puts "                                                                        \n"
      puts "Type 'lemon <command> --help' to get more information about a command.  \n"
      puts "                                                                        \n"
    end

    def load_plugin(plugin_name)
      raise Lemon::Error, "unknown command '#{plugin_name}'"\
        unless @commands.include? plugin_name

      PLUGIN_SEARCH_PATH.each do |dir|
        if File.exist?(dir + "/#{plugin_name}.rb")
          load(dir + "/#{plugin_name}.rb")
          break
        end
      end
    end

    def load_command_list
      @commands = []

      PLUGIN_SEARCH_PATH.each do |dir|
        Dir.glob(dir + '/*.rb').each do |plugin|
          @commands << File.basename(plugin).gsub(/\.rb$/, "")
        end
      end

      @commands.sort!
    end

    def execute
      if ARGV.size < 1 or [ '-h', '--help' ].include? ARGV[0]
        usage
        exit 0
      end

      # load plugin
      cmd = ARGV.shift
      load_plugin(cmd)

      check_class = Kernel.const_get("Lemon#{cmd.capitalize}Check")
      check = check_class.new
      check.run_check
    end

  end

end
