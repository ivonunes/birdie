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

    /*
     *
     * name: public Downloader
     * @param string url, string? local_file
     * @return bool (true on success)
     *
     */

    public class Downloader : Object {
      private uint64 length;
      private uint64 bytes_read;
      private int dl_length;
      public bool download_complete;
      public bool download_skip;
      private string url;
      private string local_file_path;

      public Downloader (string url, string? local_file=null) {
        download_complete = false;
        download_skip = false;
        this.url = url;
        this.local_file_path = local_file;

        // if cached, ignore
        File file = File.new_for_path (this.local_file_path);

        if (file.query_exists ()) {
            download_skip = true;
            download_complete = true;
            return;
        } else {
            download (url);
        }
      }

      private void download (string remote, int? redirects = 10) {
        ParsedURL pu = new ParsedURL (remote);
        /* http://live.gnome.org/Vala/GIONetworkingSample */
        try {
          // Resolve hostname to IP address
          var resolver = Resolver.get_default ();
          var addresses = resolver.lookup_by_name (pu.host, null);
          var address = addresses.nth_data (0);

          // Connect
          var client = new SocketClient ();
          var conn = client.connect (new InetSocketAddress (address, (uint16)pu.port));

          // Send HTTP GET request
          var message = "GET %s HTTP/1.1\r\nHost: %s\r\n\r\n".printf (pu.request, pu.host);
          conn.output_stream.write (message.data);

          // Receive response
          var response = new DataInputStream (conn.input_stream);
          size_t length=0;
          string line;
          Header header = new Header ();
          do {
            line = response.read_line (out length);
            header.add_value (line);
          } while (length > 1);
          //check and handle redirects
          if (header.code == "301" || header.code=="302") {
            //how many redirects is this?
            if (redirects <= 0) {
              debug ("Error: Too many Redirects\n");
            } else {
              //download from the redirect location
              download (header.Location, redirects--);
              return;
            }
          }
          //where is this thing going?
          string partial_file = local_file_path + ".partial";
          var file = File.new_for_path (partial_file);
          var dos = new DataOutputStream (file.create (FileCreateFlags.NONE));
          //that's it for the headers
          bytes_read = 0;
          uchar[] bytes;
          while (!conn.is_closed () && bytes_read < header.Content_Length) {
            //clear the bytes array
            bytes = {};
            bytes += response.read_byte ();
            bytes_read++;
            //write the byte
            dos.write (bytes);
          }
          //close the output stream
          dos.close();
          //move the partial file to the finished file
          FileUtils.rename (partial_file, local_file_path);
          FileUtils.remove (partial_file);
          download_complete = true;
          return;

        } catch (Error e) {
            debug ("Download manager error: %s\n", e.message);
            return;
        }
      }
    }

    public class ParsedURL {
      public string scheme;
      public string host;
      public int port;
      public string request;
      public ParsedURL(string url) {
        request = "";
        //parse that shit!
        string[] bits = url.split("://");
        scheme = bits[0];
        if (scheme.down() == "http" )
          port = 80;
        if (scheme.down() == "ftp" )
          port = 21;
        bits = bits[1].split("/");
        string hp = bits[0];
        string[] hpbits = hp.split(":");
        host = hpbits[0];
        if (hpbits.length > 1 ){
          port = int.parse(hpbits[1]);
        }
        if(bits.length > 1) {
          for (int i=1 ; i<bits.length; i++) {
            request+="/"+bits[i];
          }
        } else {
          request = "/";
        }
        debug (@"$scheme $host $port $request\n");
      }
    }

    public class Header {
      Regex key_value_regex;
      public string status;
      public string Date;
      public string Server;
      public string Location;
      public uint64 Content_Length;
      public string Content_Type;
      public string code;
      public Header() {
        try {
          key_value_regex = new Regex("(?P<key>.*):\\s+(?P<value>.*)");
        } catch (RegexError err) {
          stderr.printf(err.message+"\n");
        }
      }
      public void add_value( string line ){
        if(status==null) {
          status = line;
          var line_bits = status.split(" ");
          code = line_bits[1];
        } else {
          MatchInfo match_info;
          string key,val;
          if( key_value_regex.match(line,GLib.RegexMatchFlags.ANCHORED, out match_info) ) {
            key = match_info.fetch_named("key");
            val = match_info.fetch_named("value");
            switch (key) {
              case "Date" :
                Date = val;
                break;
              case "Server":
                Server = val;
                break;
              case "Location":
                Location = val;
                break;
              case "Content-Length":
                Content_Length = uint64.parse(val);
                break;
              case "Content-Type":
                Content_Type = val;
                break;
              default:
                break;
            }
          }
        }
      }
    }
}
