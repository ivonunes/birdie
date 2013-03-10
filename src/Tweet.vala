namespace Birdie {
    public class Tweet {
        public string id;
        public string user_name;
        public string user_screen_name;
        public string text;
        public string created_at;
        public string profile_image_url;
        public string profile_image_file;
        public bool retweeted;
        public bool favorited;

        public Tweet (string id = "", string user_name = "", string user_screen_name = "", string text = "", string created_at = "", string profile_image_url = "", string profile_image_file = "", bool retweeted = false, bool favorited = false) {
            this.id = id;
            this.user_name = user_name;
            this.user_screen_name = user_screen_name;
            this.text = text;
            this.created_at = created_at;
            this.profile_image_url = profile_image_url;
            this.profile_image_file = profile_image_file;
            this.retweeted = retweeted;
            this.favorited = favorited;
        }
    }
}
