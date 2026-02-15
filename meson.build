project('io.github.ellie_commons.reminduck', 
'vala', 'c', 
version: '2.3.1')

gnome = import('gnome')
i18n = import('i18n')


add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format (meson.project_name()), language:'c')

config_data = configuration_data()
config_data.set('version', meson.project_version())
config_data.set_quoted('LOCALEDIR', get_option('prefix') / get_option('localedir'))
config_data.set_quoted('GETTEXT_PACKAGE', meson.project_name())
config_file = configure_file(
    input: 'src/Config.vala.in',
    output: '@BASENAME@',
    configuration: config_data
)

asresources = gnome.compile_resources(
    'as-resources',
    join_paths('data', 'reminduck.gresource.xml'),
    source_dir: 'data',
    c_name: 'as'
)

subdir('src')

executable(
    meson.project_name(),
    sources,
    asresources,
    config_file,
    dependencies: [
        dependency('gtk4'),
        dependency('gee-0.8'),
        dependency('sqlite3'),
        dependency('granite-7'),
        dependency('libportal')
    ],
    install: true
)

subdir('data')
subdir('po')

gnome.post_install(
  glib_compile_schemas: true,
  gtk_update_icon_cache: true,
  update_desktop_database: true,
  )


