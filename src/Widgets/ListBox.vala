// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2013-2018 Amuza Limited
 *
 * This software is licensed under the GNU General Public License
 * (version 3 or later). See the COPYING file in this distribution.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this software; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 *
 * Authored by: Ivo Nunes <ivo@amuza.uk>
 *              Vasco Nunes <vasco@amuza.uk>
 *              Nathan Dyer <mail@nathandyer.me>
 */

namespace Birdie.Widgets {
    public class ListBox : Gtk.EventBox {
        public TwitterList list;
        public Birdie birdie;

        private Gtk.Box list_box;
        private Gtk.Alignment content_alignment;
        private Gtk.Alignment buttons_alignment;
        private Gtk.Box content_box;
        private Gtk.Box header_box;
        private Gtk.Label name_label;
        private Gtk.EventBox name_label_event;
        private Gtk.Label description_label;
        private Gtk.Label time_label;
        private Gtk.Box buttons_box;
        private Gtk.Overlay context_overlay;
        private Gtk.Button delete_button;
        private Gtk.Image delete_icon;

        private int year;
        private int month;
        private int day;
        private int hour;
        private int minute;
        private int second;

        private string date;

        public ListBox (TwitterList list, Birdie birdie) {

            this.birdie = birdie;
            this.list = list;

            this.hour = 0;
            this.minute = 0;
            this.second = 0;
            this.day = 0;
            this.month = 0;
            this.year = 0;

            // list box
            this.list_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            this.add (this.list_box);

            // Overlay
            this.context_overlay = new Gtk.Overlay ();
            this.list_box.pack_start (this.context_overlay, true, true, 0);

            // content alignment
            this.content_alignment = new Gtk.Alignment (0,0,0,1);
            this.content_alignment.top_padding = 12;
            this.content_alignment.right_padding = 12;
            this.content_alignment.bottom_padding = 12;
            this.content_alignment.left_padding = 4;
            this.content_alignment.xscale = 1;
            this.content_alignment.set_valign (Gtk.Align.START);
            this.context_overlay.add (this.content_alignment);

            // content box
            this.content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            this.content_alignment.add (this.content_box);

            // header box
            this.header_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            this.content_box.pack_start (this.header_box, false, false, 0);

            // list name label
            this.name_label = new Gtk.Label ("");
            this.name_label.set_halign (Gtk.Align.START);
            this.name_label.set_valign (Gtk.Align.START);
            this.name_label.set_selectable (false);
            this.name_label.set_markup (
                "<span underline='none' font_weight='bold' size='large'>" + list.name + 
                "</span> <span font_weight='light' color='#999'>" +
                list.owner + "</span>"
                );

            this.name_label_event = new Gtk.EventBox ();
            this.name_label_event.add (this.name_label); 

            this.name_label_event.enter_notify_event.connect ((event) => {
                event.window.set_cursor (
                    new Gdk.Cursor.from_name (Gdk.Display.get_default(), "hand2")
                );
                return false;
            });

            this.name_label_event.button_release_event.connect ((event) => {
                try {
                    GLib.Process.spawn_command_line_async ("xdg-open birdie://list/" + list.owner + "/" + list.id);
                } catch (Error e) {
                }
                return false;
            });

            this.header_box.pack_start (this.name_label_event, false, true, 0);

            // time label
            this.time_label = new Gtk.Label ("");
            this.time_label.set_halign (Gtk.Align.END);
            this.time_label.set_valign (Gtk.Align.START);
            this.update_date ();
            this.header_box.pack_start (this.time_label, true, true, 0);

            // description
            this.description_label = new Gtk.Label (list.description);
            this.description_label.set_use_markup (true);
            this.description_label.set_selectable (true);
            this.description_label.set_line_wrap (true);
            this.description_label.wrap_mode = Pango.WrapMode.WORD_CHAR;
            this.description_label.set_halign (Gtk.Align.START);
            this.description_label.set_valign (Gtk.Align.START);
            //this.description_label.xalign = 0;
            this.content_box.pack_start (this.description_label, false, true, 0);

            // css
            Gtk.StyleContext ctx = this.description_label.get_style_context ();
            ctx.add_class("tweet");

            // buttons alignment
            this.buttons_alignment = new Gtk.Alignment (0, 0, 0, 1);
            this.buttons_alignment.set_halign (Gtk.Align.END);
            this.buttons_alignment.set_valign (Gtk.Align.START);
            this.buttons_alignment.top_padding = 6;
            this.buttons_alignment.right_padding = 6;
            this.context_overlay.add_overlay (this.buttons_alignment);

            // buttons box
            this.buttons_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            this.buttons_box.set_halign (Gtk.Align.END);
            this.buttons_box.set_valign (Gtk.Align.START);
            this.buttons_box.set_no_show_all (true);
            this.buttons_box.hide ();

            // delete button
            this.delete_button = new Gtk.Button ();
            this.delete_button.set_halign (Gtk.Align.END);
            this.delete_button.set_relief (Gtk.ReliefStyle.NONE);
            this.delete_icon = new Gtk.Image.from_icon_name ("twitter-delete", Gtk.IconSize.SMALL_TOOLBAR);
            this.delete_button.child = this.delete_icon;
            this.delete_button.set_tooltip_text (_("Delete"));

            this.delete_button.clicked.connect (() => {
                // confirm deletion
                Widgets.AlertDialog confirm = new Widgets.AlertDialog (this.birdie.m_window,
                    Gtk.MessageType.QUESTION, _("Delete this list?"),
                    _("Delete"), _("Cancel"));
                Gtk.ResponseType response = confirm.run ();
                if (response == Gtk.ResponseType.OK) {
                    this.delete_button.set_sensitive (false);
                    new Thread<void*> (null, this.delete_thread);
                }
            });

            this.buttons_box.pack_start (delete_button, false, true, 0);
            this.buttons_alignment.add (this.buttons_box);

            set_events(Gdk.EventMask.BUTTON_RELEASE_MASK);
            set_events(Gdk.EventMask.ENTER_NOTIFY_MASK);
            set_events(Gdk.EventMask.LEAVE_NOTIFY_MASK);

            this.enter_notify_event.connect ((event) => {
                this.show_buttons ();
                return false;
            });

            this.leave_notify_event.connect ((event) => {
                Gtk.Allocation allocation;
                this.get_allocation (out allocation);

                if (event.x < 0 || event.x >= allocation.width ||
                    event.y < 0 || event.y >= allocation.height) {
                        this.hide_buttons ();
                }
                return false;
            });
        }

        public virtual void on_mouse_enter (Gtk.Widget widget, Gdk.EventCrossing event) {
            event.window.set_cursor (
                new Gdk.Cursor.from_name (Gdk.Display.get_default(), "hand2")
            );
        }

        public void hide_buttons () {
            this.buttons_box.hide ();
            this.time_label.show ();
        }

        public void show_buttons () {
            this.buttons_box.set_no_show_all (false);
            this.buttons_box.show_all ();
            this.buttons_box.set_no_show_all (true);
            this.time_label.hide ();
        }

        public void* delete_thread () {
            if (this.list.owner.replace("@", "") == birdie.api.account.screen_name) {
                this.birdie.api.destroy_list (this.list.id);
                
                Idle.add (() => {
                    this.birdie.lists.remove (this.list);
                    return false;
                });
            } else {
                this.birdie.api.unsubscribe_list (this.list.id);
                
                Idle.add (() => {
                    this.birdie.lists.remove (this.list);
                    return false;
                });
            }  
            return null;
        }

        public void update_date () {
            if (this.list.created_at == "") {
                this.date = "now";
            } else if (this.day == 0 || this.month == 0 || this.year == 0) {
                string year = this.list.created_at.split (" ")[5];
                this.year = int.parse (year);

                string month = this.list.created_at.split (" ")[1];
                this.month = Utils.str_to_month (month);

                string day = this.list.created_at.split (" ")[2];
                this.day = int.parse (day);

                string hms = this.list.created_at.split (" ")[3];

                string hour = hms.split (":")[0];
                this.hour = int.parse (hour);

                string minute = hms.split (":")[1];
                this.minute = int.parse (minute);

                string second = hms.split (":")[2];
                this.second = int.parse (second);
            }

            if (this.list.created_at != "") {
                this.date = Utils.pretty_date (this.year, this.month, this.day, this.hour, this.minute, this.second);
            }

            Idle.add ( () => {
                this.time_label.set_markup ("<span color='#999aaa'>" + this.date + "</span>");
                return false;
            });
        }
    }
}
