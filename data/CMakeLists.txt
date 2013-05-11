install(FILES birdie.desktop DESTINATION share/applications)
install(FILES messaging.desktop DESTINATION share/birdie)
install(FILES birdie DESTINATION share/indicators/messages/applications)
install(FILES birdie.css DESTINATION share/birdie)
INSTALL(FILES default.png DESTINATION share/birdie)
install (CODE
"execute_process (COMMAND update-desktop-database)"
)
