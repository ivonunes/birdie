namespace Birdie.Utils {
    private static Canberra.Context? sound_context = null;

    public int notify (string username, string message) {
    
        Notify.Notification notification = (Notify.Notification) GLib.Object.new(
            typeof (Notify.Notification),
            "icon-name", "birdie",
            "summary", username);
        Notify.init (GLib.Environment.get_application_name());
        notification.set_hint_string ("desktop-entry", "birdie");
        notification.set ("body", message);
        notification.set_hint_string ("sound-name", "message");   
        try {
            notification.show();
        } catch (GLib.Error error) {
            warning ("Failed to show notification: %s", error.message);
        }

        // play sound
        Canberra.Context.create (out sound_context);
        sound_context.play (0, Canberra.PROP_EVENT_ID, "message");
        
        return 0;   
    }
}
