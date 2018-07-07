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

namespace Birdie {
    public class TwitterList {
        public string id;
        public string full_name;
        public string description;
        public string created_at;
        public string name;
        public string owner;

        public TwitterList (string id = "", string full_name = "",
         string description = "", string created_at = "") {

            this.id = id;
            this.full_name = full_name;
            this.description = description;
            this.created_at = created_at;

            if (full_name != "") {
                owner = full_name.split ("/")[0];
                name = full_name.split ("/")[1];
            }
        }
    }
}
