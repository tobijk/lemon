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

  class Logger

    @@instance = nil

    def initialize(io_or_string = nil)
      @io = case io_or_string
        when String
          io_or_string == '-' ? $stderr : File.open(io_or_string, 'a+')
        when IO
          io_or_string
        when nil
          $stderr
      end
      @io.sync = true
    end

    def write(msg)
      @io.write(msg)
    end

    def close
      @io.close unless @io == $stderr
      @@instance = nil
    end

    def self.instance(io_or_stdin)
      self.close if @@instance
      @@instance = new(io_or_stdin)
      return @@instance
    end

    def self.close
      @@instance.close if @@instance
      @@instance = nil
    end

    def self.write(msg)
      raise Lemon::Error, "logging uninitialized" unless @@instance
      @@instance.write("#{Time.now} - #{msg}\n")
    end

    private_class_method :new
  end

end
