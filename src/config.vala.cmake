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

namespace Constants {
    public const string DATADIR = "@DATADIR@";
    public const string PKGDATADIR = "@PKGDATADIR@";
    public const string VERSION = "@VERSION@";
    public const string GETTEXT_PACKAGE = "@GETTEXT_PACKAGE@";
    
    // translatable strings for the .desktop file
    private const string GENERIC_NAME = _("Twitter Client");
    private const string COMMENT = _("Twitter client for elementary OS");
}
