#-*- encoding: utf-8 -*-
#
# This file is part of the Lemon Network Monitor.
# Copyright (C) 2011, Tobias Koch <tobias@tobijk.de>
#
# Lemon is licensed under the GNU General Public License, version 2. A copy of
# the license text can be found in the file LICENSE in the source distribution.
#

module Subprocess

  class Error < StandardError
  end

  attr_reader :pid, :stdin, :stdeo

  def finished?
    return true if @finished

    pid = Process.waitpid(@pid, Process::WNOHANG)
    return false if pid.nil?

    @exit_code = $?.exitstatus if $?.exited?
    @finished = true

    stopped() # signal
    return true
  end

  def wait
    return @exit_code if @finished

    Process.waitpid(@pid, 0)
    @exit_code = $?.exitstatus if $?.exited?
    @finished = true

    stopped() # signal
    return @exit_code
  end

  def exit_code
    unless finished?
      raise Subprocess::Error, "process is still running"
    else
      return @exit_code
    end
  end

  def kill(signal = "TERM")
    Process.kill(signal, @pid)
  end

  def spawn(env = {})
    stdin_r, stdin_w = IO.pipe
    stdeo_r, stdeo_w = IO.pipe

    pid = fork
    if pid
      stdin_r.close
      stdeo_w.close

      @pid, @stdin, @stdeo, @finished = pid, stdin_w, stdeo_r, false
      started() # signal
    else
      stdin_w.close
      stdeo_r.close

      $stdin.reopen(stdin_r)
      $stdout.reopen(stdeo_w)
      $stderr.reopen(stdeo_w)

      update_env(env)
      exit run()
    end
  end

  def update_env(env)
    ENV.delete_if do |key, value|
      not ['PATH', 'USER', 'USERNAME'].include?(key)
    end
    env.each_pair do |key, value|
      ENV[key] = value
    end
  end

  def method_missing(m, *args, &block)
    case m
      when :started
        #ignore
      when :stopped
        #ignore
      else
        raise NoMethodError, "undefined method `#{m}' for #{self.class}"
    end
  end

end
