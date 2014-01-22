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

namespace Birdie.Widgets {
    public class CompletionProvider : Gtk.SourceCompletionProvider, Object {
        static const unichar[] stoppers = {' ', '\n'};
        Gtk.TextMark completion_mark; /* The mark at which the proposals were generated */
        
        public string name;
        public int priority;

        private int default_account_id;    
        private Gtk.SourceView current_view;
        private Gtk.TextBuffer current_buffer;

        public CompletionProvider (Gtk.SourceView current_view, int default_account_id) {
            this.current_view = current_view;
            this.current_buffer = current_view.buffer;
            this.default_account_id = default_account_id;
        }

        public string get_name () {
            return this.name;
        }

        public int get_priority () {
            return this.priority;
        }

        public bool match (Gtk.SourceCompletionContext context) {
            return true;
        }
        
        public void populate (Gtk.SourceCompletionContext context) {        
            var file_props = get_file_proposals ();
            
            /* Get current line */
            completion_mark = current_buffer.get_insert ();
            Gtk.TextIter iter;
            current_buffer.get_iter_at_mark (out iter, completion_mark);
            var line = iter.get_line () + 1;

            Gtk.TextIter iter_start;
            current_buffer.get_iter_at_line (out iter_start, line - 1);
            
            // Proposal itself        
            if (file_props != null)
                context.add_proposals (this, file_props, true);
        }

        public bool activate_proposal (Gtk.SourceCompletionProposal proposal,
                                       Gtk.TextIter iter) {

            string to_find = "";

            Gtk.TextIter end;
            
            Gtk.TextBuffer buffer = current_buffer;
            buffer.get_iter_at_offset (out end, buffer.cursor_position);

            Gtk.TextIter start;
            buffer.get_iter_at_offset (out start, buffer.cursor_position);
            start.backward_find_char ((c) => {
                bool valid = c in stoppers;
                if (!valid)
                    to_find += c.to_string ();
                return valid;
            }, null);
            start.forward_char ();

            current_buffer.delete (ref start, ref end);
            current_buffer.insert (ref start, proposal.get_text (), proposal.get_text ().length);
            
            if ("@@" in current_buffer.text)
                current_buffer.text = current_buffer.text.replace ("@@", "@");
            if ("##" in current_buffer.text)
                current_buffer.text = current_buffer.text.replace ("##", "#");

            return true;
        }

        public Gtk.SourceCompletionActivation get_activation () {
            return Gtk.SourceCompletionActivation.INTERACTIVE |
                   Gtk.SourceCompletionActivation.USER_REQUESTED;
        }

        Gtk.Box box_info_frame = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        public unowned Gtk.Widget? get_info_widget (Gtk.SourceCompletionProposal proposal) {
            return box_info_frame;
        }

        public int get_interactive_dela () {
            return -1;
        }

        public bool get_start_it (Gtk.SourceCompletionContext context,
                                    Gtk.SourceCompletionProposal proposal,
                                    Gtk.TextIter iter) {
            var mark = current_buffer.get_insert ();
            Gtk.TextIter cursor_iter;
            current_buffer.get_iter_at_mark (out cursor_iter, mark);
            
            iter = cursor_iter;
            iter.backward_word_start ();
            return true;
        }

        public void update_info (Gtk.SourceCompletionProposal proposal, Gtk.SourceCompletionInfo info) {
            return;
        }
        
        public GLib.List<Gtk.SourceCompletionItem>? get_file_proposals () {
            /* Compute the string we want compute */
            string to_find = "";
            string last_to_find;
            Gtk.TextIter iter;
            Gtk.TextBuffer buffer = current_buffer;
            buffer.get_iter_at_offset (out iter, buffer.cursor_position);
            iter.backward_find_char ((c) => {
                bool valid = c in stoppers;
                if (!valid)
                    to_find += c.to_string ();
                return valid;
            }, null);

            to_find = to_find.reverse ();
            last_to_find = to_find;

                
            if (to_find == "")
                return null;
                
            var props = new GLib.List<Gtk.SourceCompletionItem> ();
            var db = new SqliteDatabase (true);

            foreach (var screen_name in db.get_users (this.default_account_id)) {
                if (screen_name.down ().has_prefix (to_find.down ())) {
                    var item = new Gtk.SourceCompletionItem (screen_name,
                                                            screen_name,
                                                            null,
                                                            null);
                    props.append (item);
                }
            }

            foreach (var hashtag in db.get_hashtags (this.default_account_id)) {
                if (hashtag.down ().has_prefix (to_find.down ())) {
                    var item = new Gtk.SourceCompletionItem (hashtag,
                                                            hashtag,
                                                            null,
                                                            null);
                    props.append (item);
                }
            }
                
            current_view.grab_focus ();
            
            return props;
        }
    }
}