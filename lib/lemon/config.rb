#-*- encoding: utf-8 -*-
#
# This file is part of the Lemon Network Monitor.
# Copyright (C) 2011, Tobias Koch <tobias@tobijk.de>
#
# Lemon is licensed under the GNU General Public License, version 2. A copy of
# the license text can be found in the file LICENSE in the source distribution.
#

require 'rexml/document'
require 'lemon/error'
require 'lemon/host'
require 'lemon/periodic_task'

module Lemon

  class Config
    attr_reader :global_conf, :hosts

    def initialize(filename)
      doc = File.open(filename, 'r') do |f|
        REXML::Document.new(f)
      end

      @hosts = []

      # read global configuration
      @global_conf = {}
      doc.root.attributes.each do |attr_nam, attr_val|
        @global_conf[attr_nam] = attr_val
      end

      # read list of hosts
      doc.elements.each('lemon/host') do |host_node|

        # read host configuration
        host_conf = {}
        host_node.attributes.each do |attr_nam, attr_val|
          host_conf[attr_nam] = attr_val
        end

        # create host
        config = @global_conf.merge(host_conf)
        host = Lemon::Host.new(config)

        # read lists of checks for host
        host_node.elements.each('check') do |check_node|

          # read check configuration
          check_conf = {}
          check_node.attributes.each do |attr_nam, attr_val|
            check_conf[attr_nam] = attr_val
          end

          # read check command parameters
          params = {}
          check_node.elements.each('param') do |param_node|
            pnam = param_node.attributes['name']
            pval = param_node.attributes['value']

            # replace &host; with actual host name
            pval.gsub!(/&host;/, host_conf['name'])

            case params[pnam]
              when nil
                params[pnam] = pval
              when String
                params[pnam] = [ params[pnam], pval ]
              when Array
                params[pnam] << pval
            end
          end

          check_conf['params'] = params
          config = @global_conf.merge(host_conf.merge(check_conf))

          # create and add task
          host.tasks << Lemon::PeriodicTask.new(config)
        end

        @hosts << host
      end
    end

  end

end
