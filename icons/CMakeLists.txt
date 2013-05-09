#
# App icons. These are installed to the system's default theme
#

install(FILES twitter-dm.svg DESTINATION ${CMAKE_INSTALL_PREFIX}/share/icons/hicolor/24x24/actions)
install(FILES twitter-home.svg DESTINATION ${CMAKE_INSTALL_PREFIX}/share/icons/hicolor/24x24/actions)
install(FILES twitter-mentions.svg DESTINATION ${CMAKE_INSTALL_PREFIX}/share/icons/hicolor/24x24/actions)
install(FILES twitter-profile.svg DESTINATION ${CMAKE_INSTALL_PREFIX}/share/icons/hicolor/24x24/actions)
install(FILES twitter-search.svg DESTINATION ${CMAKE_INSTALL_PREFIX}/share/icons/hicolor/24x24/actions)
install(FILES twitter-reply.svg DESTINATION ${CMAKE_INSTALL_PREFIX}/share/icons/hicolor/22x22/actions)
install(FILES twitter-retweet.svg DESTINATION ${CMAKE_INSTALL_PREFIX}/share/icons/hicolor/22x22/actions)
install(FILES twitter-retweeted.svg DESTINATION ${CMAKE_INSTALL_PREFIX}/share/icons/hicolor/22x22/actions)
install(FILES twitter-fav.svg DESTINATION ${CMAKE_INSTALL_PREFIX}/share/icons/hicolor/22x22/actions)
install(FILES twitter-favd.svg DESTINATION ${CMAKE_INSTALL_PREFIX}/share/icons/hicolor/22x22/actions)
install(FILES twitter-delete.svg DESTINATION ${CMAKE_INSTALL_PREFIX}/share/icons/hicolor/22x22/actions)
install(FILES twitter-fav-banner.svg DESTINATION ${CMAKE_INSTALL_PREFIX}/share/icons/hicolor/24x24/status)
install(FILES twitter-ret-banner.svg DESTINATION ${CMAKE_INSTALL_PREFIX}/share/icons/hicolor/24x24/status)
install(FILES twitter-favret-banner.svg DESTINATION ${CMAKE_INSTALL_PREFIX}/share/icons/hicolor/24x24/status)
install(FILES birdie.svg DESTINATION ${CMAKE_INSTALL_PREFIX}/share/icons/hicolor/scalable/apps)
install(FILES 16x16/apps/birdie.png DESTINATION ${CMAKE_INSTALL_PREFIX}/share/icons/hicolor/16x16/apps)
install(FILES 32x32/apps/birdie.png DESTINATION ${CMAKE_INSTALL_PREFIX}/share/icons/hicolor/32x32/apps)
install(FILES 48x48/apps/birdie.svg DESTINATION ${CMAKE_INSTALL_PREFIX}/share/icons/hicolor/48x48/apps)
install(FILES 64x64/apps/birdie.svg DESTINATION ${CMAKE_INSTALL_PREFIX}/share/icons/hicolor/64x64/apps)
install(FILES 128x128/apps/birdie.svg DESTINATION ${CMAKE_INSTALL_PREFIX}/share/icons/hicolor/128x128/apps)
install(FILES twitter-verified.png DESTINATION ${CMAKE_INSTALL_PREFIX}/share/icons/hicolor/22x22/emblems)
install(FILES 16x16/panel/birdie-panel.png DESTINATION ${CMAKE_INSTALL_PREFIX}/share/hicolor/16x16/panel)
install(FILES 16x16/panel-elementary/birdie-panel.png DESTINATION ${CMAKE_INSTALL_PREFIX}/share/icons/elementary/panel/16)

install(
    CODE
        "execute_process (COMMAND gtk-update-icon-cache -t -f ${CMAKE_INSTALL_PREFIX}/share/icons/hicolor)"
    CODE
        "message (STATUS \"Updated icon cache in ${CMAKE_INSTALL_PREFIX}/share/icons/hicolor\")"
)
