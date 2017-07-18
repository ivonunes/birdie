#
# App icons. These are installed to the system's default theme
#

install(FILES twitter-dm-symbolic.svg DESTINATION ${CMAKE_INSTALL_PREFIX}/share/icons/hicolor/scalable/actions)
install(FILES twitter-dm-new-symbolic.svg DESTINATION ${CMAKE_INSTALL_PREFIX}/share/icons/hicolor/scalable/actions)
install(FILES twitter-home-symbolic.svg DESTINATION ${CMAKE_INSTALL_PREFIX}/share/icons/hicolor/scalable/actions)
install(FILES twitter-mentions-symbolic.svg DESTINATION ${CMAKE_INSTALL_PREFIX}/share/icons/hicolor/scalable/actions)
install(FILES twitter-new-tweet-symbolic.svg DESTINATION ${CMAKE_INSTALL_PREFIX}/share/icons/hicolor/scalable/actions)
install(FILES twitter-reply.svg DESTINATION ${CMAKE_INSTALL_PREFIX}/share/icons/hicolor/22x22/actions)
install(FILES twitter-retweet.svg DESTINATION ${CMAKE_INSTALL_PREFIX}/share/icons/hicolor/22x22/actions)
install(FILES twitter-retweeted.svg DESTINATION ${CMAKE_INSTALL_PREFIX}/share/icons/hicolor/16x16/actions)
install(FILES twitter-favd.svg DESTINATION ${CMAKE_INSTALL_PREFIX}/share/icons/hicolor/22x22/actions)
install(FILES twitter-thread.svg DESTINATION ${CMAKE_INSTALL_PREFIX}/share/icons/hicolor/22x22/actions)
install(FILES twitter-fav-banner.svg DESTINATION ${CMAKE_INSTALL_PREFIX}/share/icons/hicolor/24x24/status)
install(FILES twitter-ret-banner.svg DESTINATION ${CMAKE_INSTALL_PREFIX}/share/icons/hicolor/24x24/status)
install(FILES twitter-favret-banner.svg DESTINATION ${CMAKE_INSTALL_PREFIX}/share/icons/hicolor/24x24/status)
install(FILES birdie.svg DESTINATION ${CMAKE_INSTALL_PREFIX}/share/icons/hicolor/scalable/apps)
install(FILES 16x16/apps/com.github.needle-and-thread.birdie.svg DESTINATION ${CMAKE_INSTALL_PREFIX}/share/icons/hicolor/16x16/apps)
install(FILES 32x32/apps/com.github.needle-and-thread.birdie.svg DESTINATION ${CMAKE_INSTALL_PREFIX}/share/icons/hicolor/32x32/apps)
install(FILES 48x48/apps/com.github.needle-and-thread.birdie.svg DESTINATION ${CMAKE_INSTALL_PREFIX}/share/icons/hicolor/48x48/apps)
install(FILES 64x64/apps/com.github.needle-and-thread.birdie.svg DESTINATION ${CMAKE_INSTALL_PREFIX}/share/icons/hicolor/64x64/apps)
install(FILES 128x128/apps/com.github.needle-and-thread.birdie.svg DESTINATION ${CMAKE_INSTALL_PREFIX}/share/icons/hicolor/128x128/apps)
install(FILES twitter-verified.png DESTINATION ${CMAKE_INSTALL_PREFIX}/share/icons/hicolor/22x22/emblems)

install(
    CODE
        "execute_process (COMMAND gtk-update-icon-cache -t -f ${CMAKE_INSTALL_PREFIX}/share/icons/hicolor)"
    CODE
        "message (STATUS \"Updated icon cache in ${CMAKE_INSTALL_PREFIX}/share/icons/hicolor\")"
)
