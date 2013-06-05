install(FILES birdie.desktop DESTINATION share/applications)
install(FILES birdie DESTINATION share/indicators/messages/applications)
INSTALL(FILES default.png DESTINATION share/birdie)
install (CODE
"execute_process (COMMAND update-desktop-database)"
)
