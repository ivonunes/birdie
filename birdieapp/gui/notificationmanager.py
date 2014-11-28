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

from gi.repository import GLib, Notify
from gettext import gettext as _
import os.path


class NotificationManager:
    def __init__(self):
        Notify.init(_("Birdie"))
        self.notification = Notify.Notification()
        #self.notification.set_category('x-gnome.network')
        self.notification.set_hint('action-icons', GLib.Variant('b', True))
        self.notification.set_hint('resident', GLib.Variant('b', True))
        self.notification.set_hint('desktop-entry',
                                   GLib.Variant('s', 'birdie'))

    def notify(self, summary, body, icon, urgency=1):
        if not os.path.exists(icon):
            icon = "birdie"
        self.notification.set_urgency(urgency)
        self.notification.update(summary, body, icon)
        self.notification.show()
