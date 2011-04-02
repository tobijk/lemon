#-*- encoding: utf-8 -*-
#
# This file is part of the Lemon Network Monitor.
# Copyright (C) 2011, Tobias Koch <tobias@tobijk.de>
#
# Lemon is licensed under the GNU General Public License, version 2. A copy of
# the license text can be found in the file LICENSE in the source distribution.
#

module Lemon

  ERR_INVOCATION = 1
  ERR_INTERRUPT  = 2
  ERR_RUNTIME    = 3

  class Error < StandardError
  end

end
