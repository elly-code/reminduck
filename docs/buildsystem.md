# Buildsystem

The buildsystem in use is Meson
the following base variable are defined once, then gets built in where relevant:

app_name (used for gettext too)
app_id
app_path
app_version



## Structure

1. meson.build

the initial meson.build define app-wide variables, set up flags and import what we need for building
Then from there everything is handled in subdirectories where logical.

there is a "development" meson option that modifies the build so it can be installed alongside stable release.
it adds also compiler flags (DEVEL) so we can do devel-specific things to help with development.

if building occurs on windows, the buildsystem automatically adjusts


2. /po/meson.build

takes care of all the translations, goes down to /po/extra/meson.build


3. /data/meson.build

first inserts variables that are defined earlier such as app_id, into various files such as
 - gresource, which holds the css stylesheets
 - metainfo
 - gschema
 - desktop file

icons are handled in /data/icons/meson.build


4. /src/meson.build

inserts variables into Config.vala.in, so the application can use them later in.

dependencies, files, and executable, are defined here.
