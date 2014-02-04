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

namespace Birdie.Media {

    public void show_media (string media_file) {
        var light_window = new Widgets.LightWindow ();
        Gtk.Image full_image;

        Gdk.Pixbuf pixbuf = Media.fit_user_screen (Environment.get_home_dir ()
            + "/.cache/birdie/media/" + media_file, light_window);

        full_image = new Gtk.Image ();
        full_image.set_from_pixbuf (pixbuf);
        full_image.set_halign (Gtk.Align.CENTER);
        full_image.set_valign (Gtk.Align.CENTER);
        light_window.add (full_image);
        light_window.set_position (Gtk.WindowPosition.CENTER);

        light_window.add_events (Gdk.EventMask.KEY_PRESS_MASK);

        // connect signal to handle key events
        light_window.key_press_event.connect ((event, key) => {
            // if Space or Esc pressed, destroy dialog
            if (key.keyval == Gdk.Key.space) {
                Idle.add (() => {
                    light_window.destroy ();
                    return false;
                });
            }
            return false;
        });

        light_window.show_all ();
    }

    public void show_youtube_video (string youtube_video_id) {
        var light_window = new Widgets.LightWindow ();
        WebKit.WebView web_view = new WebKit.WebView ();
        web_view.load_html_string ("<iframe width='640' height='390' style='margin-left: -10px; margin-top: -10px; margin-bottom: -10px;' src='http://www.youtube.com/embed/" +
            youtube_video_id + "?version=3&autohide=1&controls=2&modestbranding=1&showinfo=0&showsearch=0&vq=hd720&autoplay=1' frameborder='0'</iframe>", "http://www.youtube.com/embed/");
        light_window.add (web_view);
        light_window.set_position (Gtk.WindowPosition.CENTER);
        light_window.show_all ();
    }
}