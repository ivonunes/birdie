project('uk.amuza.birdie', 'vala', 'c')

gnome = import('gnome')
i18n = import('i18n')

add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format (meson.project_name()), language:'c')
add_project_arguments(['--vapidir', join_paths(meson.current_source_dir(), 'vapi')],
                      language: 'vala')

asresources = gnome.compile_resources(
  'as-resources', 'data/' + meson.project_name() + '.gresource.xml',
  source_dir: 'data',
  c_name: 'as'
)

executable(
  meson.project_name(),
  'src/main.vala',
  'src/config.vala',
  'src/Birdie.vala',
  'src/API.vala',
  'src/Twitter.vala',
  'src/Tweet.vala',
  'src/User.vala',
  'src/Database.vala',
  'src/TwitterList.vala',
  'src/Cache.vala',
  'src/Widgets/TweetBox.vala',
  'src/Widgets/TweetList.vala',
  'src/Widgets/MainWindow.vala',
  'src/Widgets/TweetDialog.vala',
  'src/Widgets/UserBox.vala',
  'src/Widgets/Dialogs.vala',
  'src/Widgets/Welcome.vala',
  'src/Widgets/Notebook.vala',
  'src/Widgets/MoreButton.vala',
  'src/Widgets/ListsView.vala',
  'src/Widgets/ListBox.vala',
  'src/Widgets/CompletionProvider.vala',
  'src/Widgets/ConversationsList.vala',
  'src/Widgets/ConversationView.vala',
  'src/Widgets/AccountsPopover.vala',
  'src/Media/Avatar.vala',
  'src/Media/GetMedia.vala',
  'src/Media/Parsing.vala',
  'src/Media/ShowMedia.vala',
  'src/Media/Imgur.vala',
  'src/Media/Cairo.vala',
  'src/Media/Pixbuf.vala',
  'src/Utils/Date.vala',
  'src/Utils/Notifications.vala',
  'src/Utils/Launcher.vala',
  'src/Utils/Networking.vala',
  'src/Utils/Downloader.vala',
  'src/Utils/Strings.vala',
  'src/Utils/Files.vala',
  'src/Utils/Logger.vala',
  'src/Utils/StatusIcon.vala',
  'src/Utils/System.vala',
  asresources,
  dependencies: [
    dependency('glib-2.0'),
    dependency('granite'),
    dependency('gtk+-3.0'),
    dependency('gtksourceview-3.0'),
    dependency('libsoup-2.4'),
    dependency('gee-0.8'),
    dependency('rest-0.7'),
    dependency('json-glib-1.0'),
    dependency('libnotify'),
    dependency('libcanberra'),
    dependency('gdk-x11-3.0'),
    dependency('webkit2gtk-4.0'),
    dependency('sqlite3'),
    dependency('xtst'),
    dependency('purple'),
    meson.get_compiler('c').find_library('m', required : false),
    meson.get_compiler('c').find_library('X11', required : false)
  ],
  install: true
)
subdir('data')
subdir('po')

meson.add_install_script('meson/post_install.py')

