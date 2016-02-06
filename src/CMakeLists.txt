vala_precompile(VALA_C
    main.vala
    config.vala
    Birdie.vala
    API.vala
    Twitter.vala
    Tweet.vala
    User.vala
    Database.vala
    TwitterList.vala
    Cache.vala
    Widgets/TweetBox.vala
    Widgets/TweetList.vala
    Widgets/UnifiedWindow.vala
    Widgets/TweetDialog.vala
    Widgets/UserBox.vala
    Widgets/Dialogs.vala
    Widgets/Welcome.vala
    Widgets/Notebook.vala
    Widgets/MoreButton.vala
    Widgets/ListsView.vala
    Widgets/ListBox.vala
    Widgets/CompletionProvider.vala
    Widgets/ConversationsList.vala
    Widgets/ConversationView.vala
    Widgets/AccountsPopover.vala
    Media/Avatar.vala
    Media/GetMedia.vala
    Media/Parsing.vala
    Media/ShowMedia.vala
    Media/Imgur.vala
    Media/Cairo.vala
    Media/Pixbuf.vala
    Utils/Date.vala
    Utils/Notifications.vala
    Utils/Launcher.vala
    Utils/Networking.vala
    Utils/Downloader.vala
    Utils/Strings.vala
    Utils/Files.vala
    #Utils/KeybindingManager.vala
    Utils/Logger.vala
    Utils/StatusIcon.vala
    Utils/System.vala
PACKAGES
    ${BIRDIE_PACKAGES}
OPTIONS
    ${VALAC_OPTIONS}
)

#Here we define our executable name.
add_executable(birdie
    ${VALA_C} )

add_definitions (${DEPS_CFLAGS})

#We need to link the libraries with our Executable.
target_link_libraries(birdie ${DEPS_LIBRARIES} -lX11 gthread-2.0)

install (TARGETS birdie RUNTIME DESTINATION bin)
