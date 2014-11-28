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


import os
import sys
import re
import subprocess


def is_running(process):
        try:  # Linux/Unix
            s = subprocess.Popen(["ps", "axw"], stdout=subprocess.PIPE)
        except:  # Windows
            s = subprocess.Popen(["tasklist", "/v"], stdout=subprocess.PIPE)
        for x in s.stdout:
            if re.search(process, x):
                return True
        return False


def detect_desktop_environment():
        if sys.platform in ["win32", "cygwin"]:
            return "windows"
        elif sys.platform == "darwin":
            return "mac"
        else:  # Most likely either a POSIX system or something not much common
            desktop_session = os.environ.get("DESKTOP_SESSION")
            # easier to match if we doesn't have  to deal with caracter cases
            if desktop_session is not None:
                desktop_session = desktop_session.lower()
                if desktop_session in [
                        "gnome", "unity", "cinnamon", "mate",
                        "xfce4", "lxde", "fluxbox",
                        "blackbox", "openbox", "icewm", "jwm",
                        "afterstep", "trinity", "kde"]:
                    return desktop_session
                # Special cases ##
                # Canonical sets $DESKTOP_SESSION to Lubuntu
                # rather than LXDE if using LXDE.
                elif "xfce" in desktop_session \
                        or desktop_session.startswith("xubuntu"):
                    return "xfce4"
                elif desktop_session.startswith("ubuntu"):
                    return "unity"
                elif desktop_session.startswith("lubuntu"):
                    return "lxde"
                elif desktop_session.startswith("kubuntu"):
                    return "kde"
                elif desktop_session.startswith("razor"):  # e.g. razorkwin
                    return "razor-qt"
                # e.g. wmaker-common
                elif desktop_session.startswith("wmaker"):
                    return "windowmaker"
            if os.environ.get('KDE_FULL_SESSION') == 'true':
                return "kde"
            elif os.environ.get('GNOME_DESKTOP_SESSION_ID'):
                if not "deprecated" in os.environ.get('GNOME_DESKTOP_SESSION_ID'):
                    return "gnome2"
            elif is_running("xfce-mcs-manage"):
                return "xfce4"
            elif is_running("ksmserver"):
                return "kde"
        return "unknown"
