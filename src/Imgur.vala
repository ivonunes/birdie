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

namespace Birdie {
    public class Imgur : Object {
        private static const string CLIENT_ID = "c04f7adadaa22017f95c7b002ad20240";
        private static const string URL_FORMAT = "http://api.imgur.com/2/";
        private Rest.Proxy proxy;

        public Imgur () {
            this.proxy = new Rest.Proxy (URL_FORMAT, false);
        }

        public string upload (string media_uri) throws Error {
            // open the uri and base64 encode it
            var f = File.new_for_uri (media_uri);
            var input = f.read ();

            int chunk_size = 128*1024;
            uint8[] buffer = new uint8[chunk_size];
            char[] encode_buffer = new char[(chunk_size / 3 + 1) * 4 + 4];
            size_t read_bytes;
            int state = 0;
            int save = 0;
            var encoded = new StringBuilder ();

            read_bytes = input.read (buffer);
            while (read_bytes != 0) {
                buffer.length = (int) read_bytes;
                size_t enc_len = Base64.encode_step ((uchar[]) buffer, false, encode_buffer, ref state, ref save);
                encoded.append_len ((string) encode_buffer, (ssize_t) enc_len);
                read_bytes = input.read (buffer);
            }

            size_t enc_close = Base64.encode_close (false, encode_buffer, ref state, ref save);
            encoded.append_len ((string) encode_buffer, (ssize_t) enc_close);

            var call = proxy.new_call ();

            call.set_method ("POST");
            call.set_function ("upload.json");
            call.add_param ("key", CLIENT_ID);
            call.add_param ("image", encoded.str);

            try { call.sync (); } catch (Error e) {
                debug ( call.get_payload ());
                stderr.printf ("Cannot make call: %s\n", e.message);
                return "";
            }

            var parser = new Json.Parser ();
            parser.load_from_data (call.get_payload (), (ssize_t)call.get_payload_length ());

            unowned Json.Object node_obj = parser.get_root ().get_object ();
            if (node_obj != null) {
                node_obj = node_obj.get_object_member ("upload");
                if (node_obj != null) {
                    node_obj = node_obj.get_object_member ("links");
                    if (node_obj != null) {
                        return node_obj.get_string_member ("imgur_page");
                    }
                }
            }
            return "";
        }
    }
}
