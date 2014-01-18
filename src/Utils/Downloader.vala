// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2013-2014 Birdie Developers (http://birdieapp.github.io)
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
 */

namespace Birdie.Utils {
    public class Downloader : Object {
        private string url;
        private string local_file_path;
        private File file;

        public Downloader (string url, string? local_file = null) {
            this.url = url;
            this.local_file_path = local_file;

            // if cached, ignore
            this.file = File.new_for_path (this.local_file_path);

            if (file.query_exists ()) {
                return;
            } else {
                download (url);
            }
        }

        private void download (string remote) {
            var src = File.new_for_uri (remote);
            var dst = File.new_for_path (this.local_file_path);
            try {
                debug ("Caching file from url: " + remote);
                src.copy (dst, FileCopyFlags.NONE);
            } catch (Error e) {
                stderr.printf ("%s\n", e.message);
            }
        }
    }
}
