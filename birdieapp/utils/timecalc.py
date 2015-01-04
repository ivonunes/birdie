# -*- coding: utf-8 -*-

# Copyright (C) 2013-2014  Ivo Nunes/Vasco Nunes

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.


from datetime import datetime, timedelta
import gettext
import pytz

_ = gettext.gettext


def pretty_time(otherdate):
    now = datetime.now()
    dt = now - otherdate
    offset = dt.seconds + (dt.days * 60 * 60 * 24)
    delta_s = offset % 60
    offset /= 60
    delta_m = offset % 60
    offset /= 60
    delta_h = offset % 24
    offset /= 24
    delta_d = offset

    if delta_d > 1:
        if delta_d > 6:
            date = now + \
                timedelta(days=-delta_d, hours=-delta_h, minutes=-delta_m)
            return date.strftime('%d %b %y')
        else:
            wday = now + timedelta(days=-delta_d)
            return wday.strftime('%A')
    if delta_d == 1:
        return _("Yesterday")
    if delta_h > 0:
        return _("%dh") % (delta_h)
    if delta_m > 0:
        return _("%dm") % (delta_m)
    if delta_s < 60:
        return _("just now")
    else:
        return _("%ds") % delta_s


def twitter_date_to_datetime(tweet_date):
    """Convert string to datetime"""
    created_at = datetime.strptime(tweet_date, "%a %b %d %H:%M:%S +0000 %Y")
    created_at.tzinfo = pytz.UTC
    return created_at
