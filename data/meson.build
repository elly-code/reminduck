
#========================
# GRESOURCE

gresource_file = configure_file(
    input: app_name + '.gresource.xml.in',
    output: app_id + '.gresource.xml',
    configuration: config_data,
)

gresource = gnome.compile_resources(
    'gresource',
    gresource_file,
    source_dir: '.'
)

#========================
# GSCHEMA

gschema_file = configure_file(
    input: app_name + '.gschema.xml.in',
    output: app_id + '.gschema.xml',
    configuration: config_data,
)

install_data(
    gschema_file,
    install_dir: get_option('datadir') / 'glib-2.0' / 'schemas',
)

compile_schemas = find_program('glib-compile-schemas', required: false)
if compile_schemas.found()
    test('Validate schema file', compile_schemas, args: ['--strict', '--dry-run', meson.current_source_dir()])
endif

#========================
# metainfo confuses windows, and icons are handled differently there
if not windows_build



    #========================
    # ICONS
    subdir('icons')

    #========================
    # DESKTOP
    # Inject some variables into the desktop file before merging in the translations

    desktop_file_in = configure_file(
        input: app_name + '.desktop.in.in',
        output: app_id + '.desktop.in',
        configuration: config_data,
    )

    desktop_file = i18n.merge_file(
        input: desktop_file_in,
        output: app_id + '.desktop',
        po_dir: meson.project_source_root() / 'po' / 'extra',
        type: 'desktop',
        install: true,
        install_dir: get_option('datadir') / 'applications',
    )

    desktop_utils = find_program('desktop-file-validate', required: false)
    if desktop_utils.found()
        test('Validate desktop file', desktop_utils, args: [desktop_file])
    endif


    #========================
    # METAINFO
    # Inject some variables into the metainfo file before merging in the translations

    appstream_file_in = configure_file(
        input: app_name + '.metainfo.xml.in.in',
        output: app_id + '.metainfo.xml.in',
        configuration: config_data,
    )

    appstream_file = i18n.merge_file(
        input: appstream_file_in,
        output: app_id + '.metainfo.xml',
        po_dir: meson.project_source_root() / 'po' / 'extra',
        type: 'xml',
        install: true,
        install_dir: get_option('datadir') / 'metainfo',
    )

    appstreamcli = find_program('appstreamcli', required: false)
    if appstreamcli.found()
        test('Validate appstream file', appstreamcli, args: ['validate', '--pedantic', '--no-net', '--explain', appstream_file])
    endif

endif