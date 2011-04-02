#-*- encoding: utf-8 -*-
#
# This file is part of the Lemon Network Monitor.
# Copyright (C) 2011, Tobias Koch <tobias@tobijk.de>
#
# Lemon is licensed under the GNU General Public License, version 2. A copy of
# the license text can be found in the file LICENSE in the source distribution.
#

module Lemon

  # LEMON_INSTALL_DIR is set at beginning of script

  PLUGIN_SEARCH_PATH = [ LEMON_INSTALL_DIR + '/lib/lemon/check',
    LEMON_INSTALL_DIR + '/lib/lemon/3rdparty/check' ]

  CONFIG_SEARCH_PATH = [ '/etc/lemon.xml',
    LEMON_INSTALL_DIR + '/etc/lemon.xml' ]

  LOG_FILE = '/var/log/lemond.log'
  PID_FILE = '/var/run/lemond.pid'

end
