#
# App icons. These are installed to the system's default theme
#

install(FILES twitter-dm.svg DESTINATION ${CMAKE_INSTALL_PREFIX}/share/icons/hicolor/24x24/actions)
install(FILES twitter-home.svg DESTINATION ${CMAKE_INSTALL_PREFIX}/share/icons/hicolor/24x24/actions)
install(FILES twitter-mentions.svg DESTINATION ${CMAKE_INSTALL_PREFIX}/share/icons/hicolor/24x24/actions)
install(FILES twitter-profile.svg DESTINATION ${CMAKE_INSTALL_PREFIX}/share/icons/hicolor/24x24/actions)
install(FILES twitter-search.svg DESTINATION ${CMAKE_INSTALL_PREFIX}/share/icons/hicolor/24x24/actions)

install(FILES birdie.svg DESTINATION ${CMAKE_INSTALL_PREFIX}/share/icons/hicolor/scalable/apps)

install(	
    CODE	
        "execute_process (COMMAND gtk-update-icon-cache -t -f ${CMAKE_INSTALL_PREFIX}/share/icons/hicolor)"	
    CODE
        "message (STATUS \"Updated icon cache in ${CMAKE_INSTALL_PREFIX}/share/icons/hicolor\")"
)
