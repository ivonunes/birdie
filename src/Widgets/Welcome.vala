// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2013-2014 Birdie Developers (http://launchpad.net/birdie)
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
    public class Welcome : Gtk.Box {
        public Welcome (Birdie birdie) {
            Granite.Widgets.Welcome welcome = new Granite.Widgets.Welcome (_("Birdie"), _("Twitter Client"));

            welcome.append ("add", _("Sign In"), _("Add an existing Twitter account."));
            welcome.append ("edit", _("Sign Up"), _("Create a new Twitter account."));

            welcome.activated.connect ((index) => {
                switch (index) {
                    case 0:
                        new Thread<void*> (null, birdie.request);
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
#else
    public class Welcome : Gtk.Box {
        public Welcome (Birdie birdie) {
            GLib.Object (orientation: Gtk.Orientation.VERTICAL);

            var signin = new Gtk.Button ();
            signin.set_label (_("Add an existing Twitter account."));
            signin.clicked.connect (() => {
                new Thread<void*> (null, birdie.request);
            });

            var signup = new Gtk.Button ();
            signup.set_label (_("Create a new Twitter account."));
            signup.clicked.connect (() => {
                try {
                    GLib.Process.spawn_command_line_async ("x-www-browser \"http://www.twitter.com/signup/\"");
                } catch (Error e) {
                    debug ("Could not open twitter.com/signup: " + e.message);
                }
            });

            this.set_valign (Gtk.Align.CENTER);
            this.set_halign (Gtk.Align.CENTER);
            Gtk.Label welcome_label = new Gtk.Label ("");
            welcome_label.set_markup ("<span font_weight='bold' size='x-large'>" +
                _("Welcome to Birdie") + "</span>");
            this.pack_start (welcome_label, false, false, 12);
            this.pack_start (signin, false, false, 6);
            this.pack_start (signup, false, false, 6);
            this.show_all ();
        }
    }

    public class ErrorPage : Gtk.Box {
        public ErrorPage (Birdie birdie) {
            GLib.Object (orientation: Gtk.Orientation.VERTICAL);

            var retry = new Gtk.Button ();
            retry.set_label (_("Retry"));
            retry.clicked.connect (() => {
                error_page_retry (birdie);
            });

            this.set_valign (Gtk.Align.CENTER);
            this.set_halign (Gtk.Align.CENTER);
            Gtk.Label error_label = new Gtk.Label ("");
            error_label.set_markup ("<span font_weight='bold' size='x-large'>" +
                _("Unable to connect") + "</span>");
            this.pack_start (error_label, false, false, 12);
            this.pack_start (new Gtk.Label (_("Please check your Internet Connection")), false, false, 6);
            this.pack_start (retry, false, false, 0);
            this.show_all ();
        }
    }
#endif

    void error_page_retry (Birdie birdie) {
        birdie.set_widgets_sensitive (false);

        if (birdie.initialized) {
            birdie.switch_timeline ("loading");
            birdie.switch_timeline ("home");
            new Thread<void*> (null, birdie.update_timelines);
        } else {
            birdie.switch_timeline ("loading");
            new Thread<void*> (null, birdie.init);
        }
    }
}
