#-*- encoding: utf-8 -*-
#
# This file is part of the Lemon Network Monitor.
# Copyright (C) 2011, Tobias Koch <tobias@tobijk.de>
#
# Lemon is licensed under the GNU General Public License, version 2. A copy of
# the license text can be found in the file LICENSE in the source distribution.
#

require 'io/nonblock'

class Subprocess

  class Error < StandardError
  end

  attr_reader :pid, :stdeo

  def initialize(stdin, stdeo, pid)
    @stdin = stdin
    @stdeo = stdeo
    @pid = pid
    @exit_code = nil
  end

  def io_nonblock=(nb)
    @stdeo.nonblock = nb
    @stdin.nonblock = nb
  end

  def wait
    Process.waitpid(@pid, 0)
    proc_stat = $?
    @exit_code = proc_stat.exitstatus
  end

  def exit_code
    if @exit_code.nil?
      raise Proc::Error, "process still running or wait not called"
    else
      return @exit_code
    end
  end

  def self.popen2(cmd, env = {})
    stdin_r, stdin_w = IO.pipe
    stdeo_r, stdeo_w = IO.pipe

    pid = fork
    if pid
      stdin_r.close
      stdeo_w.close

      return Subprocess.new(stdin_w, stdeo_r, pid)
    else
      stdin_w.close
      stdeo_r.close

      $stdin.reopen(stdin_r)
      $stdout.reopen(stdeo_w)
      $stderr.reopen(stdeo_w)

      update_env(env)
      exec cmd
    end
  end

  def self.update_env(env)
    ENV.delete_if do |key, value|
      not ['PATH', 'USER', 'USERNAME'].include?(key)
    end
    env.each_pair do |key, value|
      ENV[key] = value
    end
  end

end
