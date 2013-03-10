public static int main (string[] args) {
    Gdk.threads_init ();
    Gtk.init (ref args);
    var app = new Birdie.Birdie ();
    return app.run (args);
}
