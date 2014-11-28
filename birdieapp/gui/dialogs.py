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


from gi.repository import Gtk


def error_dialog(widget, title, text):
    dialog = Gtk.MessageDialog(widget, 0, Gtk.MessageType.ERROR,
                               Gtk.ButtonsType.OK, title)
    dialog.format_secondary_text(text)
    dialog.run()
    dialog.destroy()


def confirm_dialog(widget, title, text):
    dialog = Gtk.MessageDialog(
        widget.get_toplevel(), 0, Gtk.MessageType.INFO,
        Gtk.ButtonsType.YES_NO, title)
    dialog.format_secondary_text(text)
    response = dialog.run()
    dialog.destroy()
    if response == Gtk.ResponseType.YES:
        return True
    else:
        return False


def file_chooser(title):
    fc = Gtk.FileChooserDialog(title, None, Gtk.FileChooserAction.OPEN,
                               (Gtk.STOCK_CANCEL, Gtk.ResponseType.CANCEL,
                                Gtk.STOCK_OPEN, Gtk.ResponseType.OK))

    fc.set_default_response(Gtk.ResponseType.CANCEL)

    # file_filter to jpg, png and gif:
    file_filter = Gtk.FileFilter()
    file_filter.set_name("Images")
    file_filter.add_mime_type("image/png")
    file_filter.add_mime_type("image/jpeg")
    file_filter.add_mime_type("image/gif")
    file_filter.add_pattern("*.png")
    file_filter.add_pattern("*.jpg")
    file_filter.add_pattern("*.gif")
    file_filter.add_pattern("*.tif")
    fc.add_filter(file_filter)

    response = fc.run()

    if response == Gtk.ResponseType.OK:
        filename = fc.get_filename()
    elif response == Gtk.ResponseType.CANCEL:
        filename = None

    fc.destroy()

    return filename


def get_input(parent, message, default=''):
    """
    Display a dialog with a text entry.
    Returns the text, or None if canceled.
    """
    d = Gtk.MessageDialog(parent,
                          Gtk.DialogFlags.MODAL | Gtk.DialogFlags.DESTROY_WITH_PARENT,
                          Gtk.MessageType.QUESTION,
                          Gtk.ButtonsType.OK_CANCEL,
                          message)
    entry = Gtk.Entry()
    entry.set_text(default)
    entry.show()
    d.vbox.pack_end(entry, True, True, 0)
    entry.connect('activate', lambda _: d.response(Gtk.ResponseType.OK))
    d.set_default_response(Gtk.ResponseType.OK)

    r = d.run()
    text = entry.get_text().decode('utf8')
    d.destroy()
    if r == Gtk.ResponseType.OK:
        return text
    else:
        return None
