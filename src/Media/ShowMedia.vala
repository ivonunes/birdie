// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2013-2016 Birdie Developers (http://birdieapp.github.io)
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
 *              Nathan Dyer <mail@nathandyer.me>
 */

namespace Birdie.Media {

    public void show_media (string media_file, Gtk.Window main_window) {

        var dialog = new Gtk.Dialog();
        dialog.modal = true;
        dialog.set_transient_for(main_window);

        Gtk.Image full_image;

        Gdk.Pixbuf pixbuf = Media.fit_user_screen (Environment.get_home_dir ()
            + "/.cache/birdie/media/" + media_file, main_window);

        full_image = new Gtk.Image ();
        full_image.set_from_pixbuf (pixbuf);
        full_image.set_halign (Gtk.Align.CENTER);
        full_image.set_valign (Gtk.Align.CENTER);

        var image_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 12);
        image_box.add(full_image);

        dialog.add_events (Gdk.EventMask.KEY_PRESS_MASK);

        // connect signal to handle key events
        dialog.key_press_event.connect ((event, key) => {
            // if Space or Esc pressed, destroy dialog
            if (key.keyval == Gdk.Key.space) {
                Idle.add (() => {
                    dialog.destroy ();
                    return false;
                });
            }
            return false;
        });

        dialog.get_content_area().pack_start (image_box, true, true, 0);
        dialog.resizable = false;
        dialog.show_all();
    }

    public void show_youtube_video (string youtube_video_id, Gtk.Window main_window) {
        var dialog = new Gtk.Dialog();
        dialog.set_default_size(650, 400);
        dialog.modal = true;
        dialog.set_transient_for(main_window);

        var webview_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);

        WebKit.WebView web_view = new WebKit.WebView ();
        web_view.load_html ("<iframe width='640' height='390' style='margin-left: -10px; margin-top: -10px; margin-bottom: -10px;' src='http://www.youtube.com/embed/" +
            youtube_video_id + "?version=3&autohide=1&controls=2&modestbranding=1&showinfo=0&showsearch=0&vq=hd720&autoplay=1' frameborder='0'</iframe>", "http://www.youtube.com/embed/");
        
        webview_box.add(web_view);
        dialog.get_content_area().pack_start (webview_box, true, true, 0);
        dialog.resizable = false;
        dialog.show_all();
    }

    public void show_vine_clip (string vine_url, Gtk.Window main_window) {
        var dialog = new Gtk.Dialog();
        dialog.set_default_size(610, 610);
        dialog.modal = true;
        dialog.set_transient_for(main_window);

        var webview_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);

        WebKit.WebView web_view = new WebKit.WebView ();
        web_view.load_html ("<iframe src='" + vine_url + "/embed/simple' width='600'height='600' frameborder='0'> " +
            "</iframe><script src='https://platform.vine.co/static/scripts/embed.js'></script>", "http://www.vine.co/");
        
        webview_box.add(web_view);
        dialog.get_content_area().pack_start (webview_box, true, true, 0);
        dialog.resizable = false;
        dialog.show_all();
    }
}
