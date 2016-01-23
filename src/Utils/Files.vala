// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2013-2016 Birdie Developers (http://birdieapp.github.io)
 *
 * This software is licensed under the GNU General Public License
 * (version 3 or later). See the COPYING file in this distribution.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this software; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 *
 * Authored by: Ivo Nunes <ivoavnunes@gmail.com>
 *              Vasco Nunes <vascomfnunes@gmail.com>
 *              Nathan Dyer <mail@nathandyer.me>
 */

namespace Birdie.Utils {

    // creates a directory with all needed parents, relative to home

    public void create_dir_with_parents (string dir) {
            string path = Environment.get_home_dir () + dir;
            File tmp = File.new_for_path (path);
            if (tmp.query_file_type (0) != FileType.DIRECTORY) {
                GLib.DirUtils.create_with_parents (path, 0775);
            }
    }
}
