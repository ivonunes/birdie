# Translations
include (Translations)
add_translations_directory ("birdie")
add_translations_catalog ("birdie"
    ../src/Widgets
    ../src/Utils
    ../src
)

ADD_CUSTOM_TARGET(
    translations
    COMMAND xgettext -o ../../po/birdie.pot --language=C --keyword=_ --escape ../../src/*.vala ../../src/Widgets/*.vala ../../src/Utils/*.vala
)
