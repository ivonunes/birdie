// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2013 Birdie Developers (http://launchpad.net/birdie)
 *
 * This software is licensed under the GNU General Public License
 * (version 3 or later). See the COPYING file in this distribution.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this software; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 *
 * Authored by: Ivo Nunes <ivo@elementaryos.org>
 *              Vasco Nunes <vascomfnunes@gmail.com>
 */

namespace Birdie.Utils {
    public class Downloader : Object {
        public bool download_complete;
        public bool download_skip;
        private string url;
        private string local_file_path;

        public Downloader (string url, string? local_file = null) {
            download_complete = false;
            download_skip = false;
            this.url = url;
            this.local_file_path = local_file;

            // if cached, ignore
            File file = File.new_for_path (this.local_file_path);

            if (file.query_exists ()) {
                download_skip = true;
                download_complete = true;
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
                src.copy (dst, FileCopyFlags.NONE, null, null);
                download_complete = true;
            } catch (Error e) {
                stderr.printf ("%s\n", e.message);
                download_complete = false;
            }
        }
    }
}
