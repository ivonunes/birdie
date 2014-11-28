# -*- coding: utf-8 -*-

# Copyright (C) 2013-2014  Ivo Nunes/Vasco Nunes

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.


class SignalObject(object):

    def init_signals(self):
        self.signals = dict()

    def emit_signal(self, name):
        self.signals.get(name, None)()

    def emit_signal_with_arg(self, name, param):
        self.signals.get(name, None)(param)

    def emit_signal_with_args(self, name, params):
        self.signals.get(name, None)(*params)

    def connect_signal(self, name, cb):
        self.signals[name] = cb
