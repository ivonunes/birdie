namespace Birdie {
    public class User {
        public string id;
        public string name;
        public string screen_name;
        public string profile_image_url;
        public string profile_image_file;
        public string description;

        public User (string id = "", string name = "", string screen_name = "", string profile_image_url = "", string profile_image_file = "", string description = "") {
            this.id = id;
            this.name = name;
            this.screen_name = screen_name;
            this.profile_image_url = profile_image_url;
            this.profile_image_file = profile_image_file;
            this.description = description;
        }
    }
}
