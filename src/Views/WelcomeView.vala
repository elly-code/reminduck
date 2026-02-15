/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText:  2011-2019 Matheus Fantinel
 *                          2025 Stella & Charlie (teamcons.carrd.co)
 *                          2025 Contributions from the ellie_Commons community (github.com/ellie-commons/)
 */

public class Reminduck.Views.WelcomeView : Gtk.Box {

    public Granite.Placeholder welcome_widget;
    public Gtk.Button reminders_view_button;
    public Gtk.Button reminder_editor_button;
    public Gtk.Button settings_view_button;

    construct {

        orientation = Gtk.Orientation.VERTICAL;
        spacing = 24;
        margin_top = 24;
        margin_bottom = 24;
        margin_start = 24;
        margin_end = 24;
        valign = Gtk.Align.CENTER;

        add_css_class ("reminduck-welcome-box");

        var image = new Gtk.Image () {
            icon_name = "io.github.ellie_commons.reminduck",
            pixel_size = 96,
            valign = Gtk.Align.FILL
        };
        append (image);

        welcome_widget = new Granite.Placeholder ( _("QUACK! I'm Reminduck")) {
                description = _("The duck that reminds you"),
                valign = Gtk.Align.FILL
        };
        append (welcome_widget);

        reminder_editor_button = this.welcome_widget.append_button (
                new ThemedIcon ("document-new"),
                _("New Reminder"),
                _("Create a new reminder for a set date and time")
        );

        reminders_view_button = this.welcome_widget.append_button (
            new ThemedIcon ("accessories-text-editor"),
            _("View Reminders"),
            _("See reminders you've created")
        );

        settings_view_button = this.welcome_widget.append_button (
            new ThemedIcon ("open-menu"),
            _("Settings"),
            _("Tweak a few things")
        );

    }
}