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
 * Authored by: Ivo Nunes <ivoavnunes@gmail.com>
 *              Vasco Nunes <vascomfnunes@gmail.com>
 */

namespace Birdie.Widgets
{
#if HAVE_GRANITE
    public class Notebook : Granite.Widgets.StaticNotebook {
        public Notebook () {
        	this.get_style_context ().add_class (Granite.StyleClass.CONTENT_VIEW);
        }

        public void set_tabs (bool show) {
        	this.set_switcher_visible (show);
        }

        public void set_border (bool show) {
        }
    }
#else
    public class Notebook : Gtk.Notebook {
        public Notebook () {
        	this.show_border = false;
        }

        public void set_tabs (bool show) {
        	this.show_tabs = show;
        }

        public void set_border (bool show) {
        	this.show_border = show;
        }
    }
#endif
}