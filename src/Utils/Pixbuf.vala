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

    // returns a resized pixbuf to fit the current user's screen resolution
    public Gdk.Pixbuf fit_user_screen (string image_path, Gtk.Widget widget) {

        int screen_height;
        int screen_width;
        double factor;
        double new_width;
        double new_height;

        Gdk.Pixbuf pixbuf;

        try {
            pixbuf = new Gdk.Pixbuf.from_file (image_path);
        } catch (Error e) {
            error ("Error resizing image: %s", e.message);
        }

        // get screen resolution height
        screen_height = widget.get_screen ().height ();
        // get screen resolution width
        screen_width = widget.get_screen ().width ();

        // check if the image is larger than current screen height
        if (pixbuf.get_height () >= screen_height) {
            // formula to resize the image mantaining its proportions
            factor = (double)pixbuf.get_width () / pixbuf.get_height ();
            new_width = factor * (screen_height-100);
            pixbuf = pixbuf.scale_simple ((int)new_width, screen_height-100, Gdk.InterpType.BILINEAR);
        }

        // check if the image is larger than current screen width
        if (pixbuf.get_width () >= screen_width) {
            // formula to resize the image mantaining its proportions
            factor = (double)pixbuf.get_height () / pixbuf.get_width ();
            new_height = factor * (screen_width-100);
            pixbuf.scale_simple (screen_width-100, (int)new_height, Gdk.InterpType.BILINEAR);
        }
        return pixbuf;
    }
}
