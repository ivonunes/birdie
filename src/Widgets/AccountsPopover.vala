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

namespace Birdie.Widgets {

    public class AccountsPopover : Gtk.Popover {

    	public signal void switch_account(User u);
    	public signal void add_account();
    	public signal void view_profile();

    	private Gtk.Label current_account_name_label;
  
    	private Gtk.Box   user_account_box;

    	public AccountsPopover() {

    		current_account_name_label = new Gtk.Label("");
    		current_account_name_label.get_style_context().add_class("h3");
    		current_account_name_label.halign = Gtk.Align.START;
    		current_account_name_label.use_markup = true;
    		current_account_name_label.margin_left = 13;

    		var content_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 5);
    		user_account_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 5);

    		var view_profile_button = new Gtk.Button.with_label(_("View profile"));
    		view_profile_button.relief = Gtk.ReliefStyle.NONE;
    		view_profile_button.clicked.connect(() => { view_profile(); });
    		view_profile_button.halign = Gtk.Align.START;

    		var new_account_button = new Gtk.Button.with_label(_("Add account"));
    		new_account_button.relief = Gtk.ReliefStyle.NONE;
    		new_account_button.halign = Gtk.Align.START;
    		new_account_button.clicked.connect(() => { add_account(); });

            var open_collective_button = new Gtk.Button.with_label(_("Become a sponsor"));
    		open_collective_button.relief = Gtk.ReliefStyle.NONE;
    		open_collective_button.halign = Gtk.Align.START;
    		open_collective_button.clicked.connect(() => { open_collective(); });

            var report_issue_button = new Gtk.Button.with_label(_("Report an issue"));
    		report_issue_button.relief = Gtk.ReliefStyle.NONE;
    		report_issue_button.halign = Gtk.Align.START;
    		report_issue_button.clicked.connect(() => { report_issue(); });

    		var top_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
    		top_box.add(current_account_name_label);
    		top_box.add(view_profile_button);

    		content_box.margin_top = 5;
    		content_box.margin_bottom = 5;

    		content_box.add(top_box);
    		content_box.add(new Gtk.Separator(Gtk.Orientation.HORIZONTAL));
    		content_box.add(user_account_box);
    		content_box.add(new_account_button);
            content_box.add(new Gtk.Separator(Gtk.Orientation.HORIZONTAL));
            content_box.add(open_collective_button);
            content_box.add(report_issue_button);

    		this.add(content_box);
    	}

    	public void set_accounts(List<User?> all_accounts) {

    		foreach(var w in user_account_box.get_children()) {
                user_account_box.remove(w);
            }

            foreach (var account in all_accounts) {

                try {

                	var account_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
                	account_box.set_tooltip_text(_("Switch to the %s account".printf(account.name)));

                	// Avatar
                    var avatar = new Granite.Widgets.Avatar.from_file (Environment.get_home_dir () +
                        "/.local/share/birdie/avatars/" + account.profile_image_file, 32);
                    account_box.add(avatar);

                    // Labels
                    var name_label = new Gtk.Label(account.name);
                    name_label.get_style_context().add_class("h4");
                    var handle_label = new Gtk.Label("@" + account.screen_name);
                    name_label.halign = Gtk.Align.START;
                    handle_label.halign = Gtk.Align.START;

                    var label_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 3);
                    label_box.add(name_label);
                    label_box.add(handle_label);
                    account_box.add(label_box);

  					// The button itself
  					var account_button = new Gtk.Button();
  					account_button.relief = Gtk.ReliefStyle.NONE;
  					account_button.add(account_box);

                    account_button.clicked.connect (() => {
                        switch_account (account);
                    });

                    user_account_box.add(account_button);

                } catch (Error e) {
                    stderr.printf("Error adding account to popover: %s\n", e.message);
                }
            }
    	}

    	public void set_current_account(User account) {
    		current_account_name_label.label = "<b>" + account.name + "</b>";
    		current_account_name_label.show();
    	}

        public void open_collective() {
            GLib.Process.spawn_command_line_async ("xdg-open https://opencollective.com/birdie");
        }

        public void report_issue() {
            GLib.Process.spawn_command_line_async ("xdg-open https://github.com/ivonunes/birdie/issues");
        }
	}
}
