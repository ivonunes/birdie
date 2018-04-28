// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2013-2018 Amuza Limited
 *
 * This software is licensed under the GNU General Public License
 * (version 3 or later). See the COPYING file in this distribution.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this software; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 *
 * Authored by: Ivo Nunes <ivo@amuza.uk>
 *              Vasco Nunes <vasco@amuza.uk>
 *              Nathan Dyer <mail@nathandyer.me>
 */

namespace Birdie.Utils {
    [DBus (name = "org.Cinnamon")]
    public interface cinna : GLib.Object {
        public abstract string CinnamonVersion { owned get; }
    }

    public bool is_cinnamon () {
        string cv;

        try {
	        cinna c = GLib.Bus.get_proxy_sync (BusType.SESSION, "org.Cinnamon", "/org/Cinnamon");
	        cv = c.CinnamonVersion;
        } catch (Error e) {
            return false;
        }

        if (cv == null) {
	        return false;
        } else {
	        return true;
        }
    }

    [DBus (name = "org.gnome.Shell")]
    public interface GnomeShell : GLib.Object {
        public abstract string ShellVersion { owned get; }
    }

    public bool is_gnome () {
        string gsv = null;

        try {
	        GnomeShell gs = GLib.Bus.get_proxy_sync (BusType.SESSION, "org.gnome.Shell", "/org/gnome/Shell");
	        gsv = gs.ShellVersion;
        } catch (Error e) {
            return false;
        }

        if (gsv == null) {
	        return false;
        } else {
	        return true;
        }
    }
}
