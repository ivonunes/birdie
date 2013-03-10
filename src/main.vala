public static int main (string[] args) {
    Gtk.init (ref args);
    var app = new Birdie.Birdie ();
    return app.run (args);
}