// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2013-2018 Ivo Nunes
 *
 * This software is licensed under the GNU General Public License
 * (version 3 or later). See the COPYING file in this distribution.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this software; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 *
 * Authored by: Ivo Nunes <ivonunes@me.com>
 *              Vasco Nunes <vasco.m.nunes@me.com>
 *              Nathan Dyer <mail@nathandyer.me>
 */

namespace Birdie.Utils {
    public static int str_to_month (string month) {
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

    public static string pretty_date (int year, int month, int day, int hour, int minute, int second) {
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

    public bool timeout_is_dead (int timeout_period, DateTime last_timeout) {
        var now = new DateTime.now_utc ();

        var diff = now.difference (last_timeout);

        var time = new DateTime.local (1, 1, 1, 0, 0, 0);
        time = time.add (diff);

        int diff_year = time.get_year () - 1;
        int diff_month = time.get_month () - 1;
        int diff_day = time.get_day_of_month () - 1;
        int diff_hour = time.get_hour ();
        int diff_minute = time.get_minute ();

        if (diff_year > 0 || diff_month > 0 || diff_day > 0 ||
        	diff_hour > 0 || diff_minute > (timeout_period + 1)) {
            return true;
        }

        return false;
    }
}
