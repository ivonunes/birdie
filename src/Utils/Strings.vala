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

    string highlight_all (owned string text) {
        text = unescape_html (text);
        text = escape_markup (text);
        text = highlight_urls (text);
        text = highlight_hashtags (text);
        text = highlight_users (text);
        return text;
    }

    string highlight_hashtags (owned string text) {
        Regex hashtags;

        try {
            try { 
                hashtags = new Regex("\\B([#][[:alpha:]0-9_.-\\p{Latin}\\p{Greek}]+)");
            } catch (RegexError e) {
                hashtags = new Regex("\\B([#][[:alpha:]0-9_]+)");
            }

            text = hashtags.replace(text, -1, 0,
                "<span underline='none'><a href='birdie://search/\\0'>\\0</a></span>");
        } catch (RegexError e) {
            warning ("regex error: %s", e.message);
        }
        return text;
    }

    string[] get_hashtags_list (string text) {
        Regex? hashtags = null;

        try {
            try { 
                hashtags = new Regex("\\B([#][[:alpha:]0-9_.-\\p{Latin}\\p{Greek}]+)");
            } catch (RegexError e) {
                hashtags = new Regex("\\B([#][[:alpha:]0-9_]+)");
            }
        } catch (RegexError e) {
            warning ("regex error: %s", e.message);
        }

        return hashtags.split (text);
    }

    string highlight_users (owned string text) {
        Regex users;

        try {
            users = new Regex("\\B([@][[:alpha:]0-9_]+)");
            text = users.replace(text, -1, 0,
                "<span underline='none'><a href='birdie://user/\\0'>\\0</a></span>");
        } catch (RegexError e) {
            warning ("regex error: %s", e.message);
        }
        return text;
    }

    string highlight_urls (owned string text) {
        text = Purple.markup_linkify (text);
        text = text.replace ("<A HREF", "<span underline='none'><a href");
        text = text.replace ("</A>", "</a></span>");

        var text_split = text.split ("<a href=\"");

        if (text_split.length > 1) {
            foreach (var part in text_split) {
                var partofpart = part.split("\">");
                if (partofpart.length > 1) {
                    text = text.replace (partofpart[0], partofpart[0].replace ("&", "&amp;"));
                }
            }
        }

        return text;
    }

    string remove_html_tags (string input) {
        var without_html_tags = Purple.markup_strip_html (input);

        foreach (var part in without_html_tags.split (" ")) {
            if ("(birdie://" in part)
                without_html_tags = without_html_tags.replace (part, "");
        }

        without_html_tags = without_html_tags.replace ("  ", " ");

        return without_html_tags;
    }

    string unescape_html (owned string text) {
        return Purple.unescape_html (text);
    }

    string escape_markup (owned string text) {
        return GLib.Markup.escape_text (text);
    }
}
