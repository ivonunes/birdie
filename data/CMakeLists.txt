install(FILES com.github.needle-and-thread.birdie.desktop DESTINATION share/applications)
INSTALL(FILES default.png DESTINATION share/birdie)
INSTALL(FILES media.png DESTINATION share/birdie)
install(FILES com.github.needle-and-thread.birdie.appdata.xml DESTINATION share/appdata)
install (CODE
"execute_process (COMMAND update-desktop-database)"
)
