// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2013-2019 Ivo Nunes
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

namespace Birdie.Widgets
{
    public class Welcome : Gtk.Box {
        public Welcome (Birdie birdie) {
            Granite.Widgets.Welcome welcome = new Granite.Widgets.Welcome (_("Welcome to Birdie"), _("Let's get started."));

            welcome.append ("list-add", _("Sign In"), _("Add an existing Twitter account."));
            welcome.append ("edit", _("Sign Up"), _("Create a new Twitter account."));

            welcome.activated.connect ((index) => {
                switch (index) {
                    case 0:
                        birdie.request.begin ();
                        break;
                    case 1:
                        try {
                            GLib.Process.spawn_command_line_async ("xdg-open \"http://www.twitter.com/signup/\"");
                        } catch (Error e) {
                            debug ("Could not open twitter.com/signup: " + e.message);
                        }
                        break;
                }
            });

            this.pack_start (welcome, true, true, 0);
            this.show_all ();
        }
    }

    public class ErrorPage : Gtk.Box {
        public ErrorPage (Birdie birdie) {
            Granite.Widgets.Welcome welcome = new Granite.Widgets.Welcome (_("Unable to connect"), _("Please check your Internet Connection"));

            welcome.append ("view-refresh", _("Retry"), _("Try to connect again"));

            welcome.activated.connect (() => {
                error_page_retry (birdie);
            });

            this.pack_start (welcome, true, true, 0);
            this.show_all ();
        }
    }


    void error_page_retry (Birdie birdie) {
        birdie.set_widgets_sensitive (false);

        if (birdie.initialized) {
            birdie.switch_timeline ("loading");
            birdie.switch_timeline ("home");
            new Thread<void*> (null, birdie.update_timelines);
        } else {
            birdie.switch_timeline ("loading");
            birdie.init.begin ();
        }
    }
}
