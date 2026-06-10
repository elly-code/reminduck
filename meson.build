project(
    'reminduck', 
    'vala', 'c', 
    version: '2.3.1',
    license: 'GPL-3.0-or-later'
    )

app_name = meson.project_name()
correct_app_id = 'io.github.elly_code.' + app_name
correct_app_path = '/io/github/elly_code/' + app_name

legacy_app_id = 'io.github.ellie_commons.' +  app_name
legacy_app_path = '/io/github/ellie_commons/' + app_name

app_version = meson.project_version()

if get_option('legacy-rdnn')
    app_id = legacy_app_id
    alternate_app_id = correct_app_id
    app_path = legacy_app_path

else
    app_id = correct_app_id
    alternate_app_id = legacy_app_id
    app_path = correct_app_path

endif


vala_flags = []

development_build = get_option('development')
if development_build
  app_id +=  '.devel'
  vala_flags += ['--define', 'DEVEL']
endif


#================================
gnome = import('gnome')
i18n = import('i18n')

# Windows needs icons, special arguments, and skip libportal
windows_build = get_option('windows_build')
if build_machine.system() == 'windows'
    windows_build = true
endif

if windows_build
    vala_flags += ['--define', 'WINDOWS']
endif

add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format (app_name), language:'c')



#================================
# Add subfolders for Meson to look

config_data = configuration_data()
config_data.set('APP_NAME', app_name)
config_data.set('APP_ID', app_id)
config_data.set('APP_PATH', app_path)
config_data.set('APP_VERSION', app_version)
config_data.set('ALTERNATE_APP_ID', alternate_app_id)
config_data.set('LOCALEDIR', get_option('prefix') / get_option('localedir'))

subdir('po')
subdir('data')
subdir('src')


if not windows_build
    gnome.post_install(
      glib_compile_schemas: true,
      gtk_update_icon_cache: true,
      update_desktop_database: true
    )
endif
