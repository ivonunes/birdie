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

import os.path
import cPickle
from birdieapp.constants import BIRDIE_LOCAL_SHARE_PATH, BIRDIE_CACHE_PATH
from birdieapp.userstore import UserStore


def load_pickle(file_path):
    """load a pickle from file if it exists. returns the object"""
    if os.path.isfile(file_path):
        file_handler = open(file_path, "rb")
        obj = cPickle.load(file_handler)
        file_handler.close()
        assert isinstance(obj, list)
        return obj
    else:
        return list()


def load_users(file_path):
    """load a pickle of users if it exists. returns the object"""
    if os.path.isfile(file_path):
        file_handler = open(file_path, "rb")
        obj = cPickle.load(file_handler)
        file_handler.close()
        assert isinstance(obj, UserStore)
        return obj
    else:
        return UserStore()


def write_pickle(file_path, obj):
    """write a pickle"""
    file_handler = open(file_path, "wb")
    cPickle.dump(obj, file_handler)
    file_handler.close()


def check_required_dirs():
    """Create required dirs if they do not exist"""
    if not os.path.isdir(BIRDIE_LOCAL_SHARE_PATH):
        os.makedirs(BIRDIE_LOCAL_SHARE_PATH)
    if not os.path.isdir(BIRDIE_CACHE_PATH):
        os.makedirs(BIRDIE_CACHE_PATH)
