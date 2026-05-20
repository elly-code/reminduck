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
        vexpand = true;

        add_css_class ("reminduck-welcome-box");

        var image = new Gtk.Image () {
            icon_name = APP_ID,
            pixel_size = 96,
            valign = Gtk.Align.CENTER
        };
        append (image);

        var title_label = new Gtk.Label (_("QUACK! I'm Reminduck")) {
            margin_top = 12
        };
        title_label.add_css_class (Granite.STYLE_CLASS_H2_LABEL);
        append (title_label);

        var desc_label = new Gtk.Label (_("The duck that reminds you"));
        desc_label.add_css_class (Granite.STYLE_CLASS_DIM_LABEL);
        append (desc_label);

        var button_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6) {
            halign = Gtk.Align.CENTER,
            valign = Gtk.Align.CENTER,
            vexpand = true
        };

        reminder_editor_button = new Gtk.Button.with_label (_("New Reminder")) {
            width_request = 200
        };
        reminder_editor_button.add_css_class (Granite.STYLE_CLASS_SUGGESTED_ACTION);
        button_box.append (reminder_editor_button);

        reminders_view_button = new Gtk.Button.with_label (_("View Reminders")) {
            width_request = 200
        };
        button_box.append (reminders_view_button);

        settings_view_button = new Gtk.Button.with_label (_("Settings")) {
            width_request = 200
        };
        button_box.append (settings_view_button);

        append (button_box);
    }
}