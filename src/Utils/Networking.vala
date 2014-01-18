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

    bool check_internet_connection () {
        var host = "http://www.twitter.com";

        try {
            // Resolve hostname to IP address
            var resolver = ProxyResolver.get_default ();
            resolver.lookup (host, null);
        } catch (Error e) {
            debug ("%s\n", e.message);
            return false;
        }
        return true;
    }
}
