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

namespace Birdie.Utils {

    string highlight_all (owned string text) {
        text = highlight_urls (text);
        text = highlight_hashtags (text);
        text = highlight_users (text);
        text = text.replace ("&", "&amp;");

        return text;
    }

    string highlight_hashtags (owned string text) {
        Regex urls;

        try {
            urls = new Regex("([#][[:alpha:]0-9_]+)");
            text = urls.replace(text, -1, 0,
                "<span underline='none'><a href='birdie://search/\\0'>\\0</a></span>");
        } catch (RegexError e) {
            warning ("regex error: %s", e.message);
        }
        return text;
    }

    string highlight_users (owned string text) {
        Regex urls;

        try {
            urls = new Regex("([@][[:alpha:]0-9_]+)");
            text = urls.replace(text, -1, 0,
                "<span underline='none'><a href='birdie://user/\\0'>\\0</a></span>");
        } catch (RegexError e) {
            warning ("regex error: %s", e.message);
        }
        return text;
    }

    string highlight_urls (owned string text) {
        Regex urls;

        try {
            urls = new Regex("((http|https|ftp)://(([[:alpha:]0-9?=_#\\-&~+=,%$!]|[/.]|[~])*)\\b)");
            text = urls.replace(text, -1, 0,
                "<span underline='none'><a href='\\0'>\\0</a></span>");
            if ("</a></span>/" in text)
                text = text.replace ("</a></span>/", "/</a></span>");
        } catch (RegexError e) {
            warning ("regex error: %s", e.message);
        }
        return text;
    }

    string unescape_html_entitites (string text) {
        string txt = text;
        txt = txt.replace ("&amp;", "&");
        txt = txt.replace ("&lt;", "<");
        txt = txt.replace ("&gt;", ">");
        return txt;
    }
}
