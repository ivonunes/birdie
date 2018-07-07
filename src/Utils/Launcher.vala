// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2013-2018 Ivo Nunes
 *
 * This software is licensed under the GNU General Public License
 * (version 3 or later). See the COPYING file in this distribution.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this software; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 *
 * Authored by: Ivo Nunes <ivonunes@me.com>
 *              Vasco Nunes <vasco.m.nunes@me.com>
 *              Nathan Dyer <mail@nathandyer.me>
 */

namespace Birdie.Utils {

    public class Launcher : Object {
    #if HAVE_LIBUNITY
        private Unity.LauncherEntry? launcher = null;

        Birdie birdie;

        public Launcher(Birdie birdie) {
            this.birdie = birdie;
            launcher = Unity.LauncherEntry.get_for_desktop_id ("birdie.desktop");
        }

        public void set_count (int count) {

            launcher.count = count;
            if (count > 0)
                launcher.count_visible = true;
            else
                clean_launcher_count ();
        }

        public void clean_launcher_count () {
            launcher.count = 0;
            launcher.count_visible = false;
        }
    #else
        public Launcher(Birdie birdie) {
        }
    #endif
    }
}
