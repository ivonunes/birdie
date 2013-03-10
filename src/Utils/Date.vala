namespace Birdie.Utils {
    public int str_to_month (string month) {
        switch (month) {
            case "Jan":
                return 1;
            case "Feb":
                return 2;
            case "Mar":
                return 3;
            case "Apr":
                return 4;
            case "May":
                return 5;
            case "Jun":
                return 6;
            case "Jul":
                return 7;
            case "Aug":
                return 8;
            case "Sep":
                return 9;
            case "Oct":
                return 10;
            case "Nov":
                return 11;
            case "Dec":
                return 12;
        }
        
        return 0;
    }
    
    public string pretty_date (int year, int month, int day, int hour, int minute, int second) {
        var now = new DateTime.now_utc ();
        var begin = new DateTime.utc (year, month, day, hour, minute, (double) second);
        
        var diff = now.difference (begin);
        
        var time = new DateTime.local (1, 1, 1, 0, 0, 0);
        time = time.add (diff);
        
        int diff_year = time.get_year () - 1;
        int diff_month = time.get_month () - 1;
        int diff_day = time.get_day_of_month () - 1;
        int diff_hour = time.get_hour ();
        int diff_minute = time.get_minute ();   
        
        if (diff_year > 0) {
            return _("%d y").printf (diff_year);
        } else if (diff_month > 0) {
            int t = diff_month;
            return _("%d mo").printf (t);
        } else if (diff_day > 7) {
            int t = (diff_day) / 7;
            return _("%d w").printf (t);
        } else if (diff_day > 0) {
            int t = diff_day;
            return _("%d d").printf (t);
        } else if (diff_hour > 0) {
            return _("%d h").printf (diff_hour);
        } else if (diff_minute > 0) {
            return _("%d m").printf (diff_minute);
        }
    
        return _("now");
        
    }
}
