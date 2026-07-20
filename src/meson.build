

#================================
# Config.vala allows us to set variables in Meson, for the Vala app to use later

config_file = configure_file(
    input: 'Config.vala.in',
    output: '@BASENAME@',
    configuration: config_data
)

#================================

# Gee to hold all these reminders
# Libportal to set autostart
# SQLite for the storage system

dependencies = [
        dependency('gtk4'),
        dependency('granite-7', version: '>=7.4.0'),
        dependency('gee-0.8'),
        dependency('sqlite3')
    ]


#================================
sources = files (
    'Application.vala',
    'Constants.vala',
    'MainWindow.vala',
    'Services/Database.vala',
    'Services/Utils.vala',
    'Objects/Reminder.vala',
    'Objects/Quack.vala',
    'Widgets/RepeatBox.vala',
    'Widgets/QuackBox.vala',
    'Views/ReminderEditor.vala',
    'Views/RemindersView.vala',
    'Views/WelcomeView.vala',
    'Views/SettingsView.vala',
)


#================================
# Windows specific stuff
# theres a gio-windows and a gio-unix. We need to add depending on case 
# We need to compile an icon and add to the sources to avoid "missing icon" icon at every turn
# So AFAIK ico.rc just point to an ico file in the same folder it is, so this is like gresource
# No libportal on windows

if windows_build
    dependencies += dependency('gio-windows-2.0')
    ico_src = import('windows').compile_resources('../windows/icons/ico.rc')
    sources += ico_src

else
    dependencies += dependency('gio-unix-2.0')
    dependencies += dependency('libportal')
#    sources += files('Utils' / 'Libportal.vala')

endif


executable(
    app_id,
    gresource,
    config_file,
    sources,
    dependencies: dependencies,
    vala_args: vala_flags,
    win_subsystem: 'windows',
    install: true
)
