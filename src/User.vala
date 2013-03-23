namespace Birdie {
    public class User {
        public string id;
        public string name;
        public string screen_name;
        public string profile_image_url;
        public string profile_image_file;
        public string location;
        public string desc;
        public int64 friends_count;
        public int64 followers_count;
        public int64 statuses_count;

        public User (string id = "", string name = "",
            string screen_name = "", string profile_image_url = "",
            string profile_image_file = "", string location = "",
            string desc = "", int64 friends_count = 0,
            int64 followers_count = 0, int64 statuses_count = 0
            ) {

            this.id = id;
            this.name = name;
            this.screen_name = screen_name;
            this.profile_image_url = profile_image_url;
            this.profile_image_file = profile_image_file;
            this.location = location;
            this.desc = desc;
            this.friends_count = friends_count;
            this.followers_count = followers_count;
            this.statuses_count = statuses_count;
        }
    }
}
