/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText:  2011-2019 Matheus Fantinel
 *                          2025 Stella & Charlie (teamcons.carrd.co)
 *                          2025 Contributions from the ellie_Commons community (github.com/ellie-commons/)
 */

/**
 * The MainWindow is built around a Stack, to switch between Views
 * The Welcome view allows choosing which one to go to
 * Individual views may request the window to change to another view
 */
public class Reminduck.MainWindow : Gtk.ApplicationWindow {

    private GLib.Settings settings;
    public Granite.Settings granite_settings;

    Gtk.Stack stack;
    Gtk.HeaderBar headerbar;
    Gtk.Revealer back_revealer;
    Gtk.Button back_button;

    Reminduck.Views.WelcomeView welcome_view;
    Reminduck.Views.ReminderEditor reminder_editor;
    Reminduck.Views.RemindersView reminders_view;
    Reminduck.Views.SettingsView settings_view;

    private enum View {WELCOME, EDIT, ALL, TWEAK}

    construct {
        Intl.setlocale ();
        settings = new GLib.Settings ("io.github.ellie_commons.reminduck.state");

        set_default_size (
            this.settings.get_int ("window-width"),
            this.settings.get_int ("window-height")
        );

        // Use reminduck styling
        var app_provider = new Gtk.CssProvider ();
        app_provider.load_from_resource ("/io/github/ellie_commons/reminduck/Application.css");

        Gtk.StyleContext.add_provider_for_display (
            Gdk.Display.get_default (),
            app_provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION + 1
        );

        title = _("Reminduck");
        Gtk.Label title_widget = new Gtk.Label (_("Reminduck"));
        title_widget.add_css_class (Granite.STYLE_CLASS_TITLE_LABEL);

        headerbar = new Gtk.HeaderBar () {
            title_widget = title_widget
        };
        headerbar.add_css_class ("default-decoration");
        set_titlebar (headerbar);

        granite_settings = Granite.Settings.get_default ();
            if (granite_settings.prefers_color_scheme == DARK) {
                this.headerbar.add_css_class ("reminduck-headerbar-dark");
            } else {
                this.headerbar.remove_css_class ("reminduck-headerbar-dark");
            }

        granite_settings.notify["prefers-color-scheme"].connect (() => {
            if (granite_settings.prefers_color_scheme == DARK) {
                this.headerbar.add_css_class ("reminduck-headerbar-dark");
            } else {
                this.headerbar.remove_css_class ("reminduck-headerbar-dark");
            }
        });

        this.back_button = new Gtk.Button.with_label (_("Back")) {
            valign = Gtk.Align.CENTER,
            tooltip_text = _("Click to return to main view")
        };
        this.back_button.add_css_class (Granite.STYLE_CLASS_BACK_BUTTON);

        back_revealer = new Gtk.Revealer () {
            child = back_button,
            reveal_child = false,
            transition_type = Gtk.RevealerTransitionType.SWING_LEFT
        };

        this.headerbar.pack_start (back_revealer);

        this.back_button.clicked.connect (() => {
            this.show_welcome_view ();
        });

        /* ---------------- BODY ---------------- */
        stack = new Gtk.Stack () {
            transition_duration = 500,
            hexpand = vexpand = true,
            halign = Gtk.Align.FILL,
            valign = Gtk.Align.FILL,
            transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT
        };

        welcome_view = new Reminduck.Views.WelcomeView ();
        stack.add_named (welcome_view, "welcome");

        this.build_reminder_editor ();
        this.build_reminders_view ();
        this.build_settings_view ();

        var handle = new Gtk.WindowHandle () {
            child = stack
        };

        child = handle;

        this.show_welcome_view (Gtk.StackTransitionType.NONE);

        /* ---------------- CONNECTS AND BINDS ---------------- */
        welcome_view.reminder_editor_button.clicked.connect (() => {
            show_reminder_editor ();
        });

        welcome_view.reminders_view_button.clicked.connect (() => {
            show_reminders_view (Gtk.StackTransitionType.SLIDE_LEFT);
        });

        welcome_view.settings_view_button.clicked.connect (() => {
            show_settings_view (Gtk.StackTransitionType.SLIDE_LEFT);
        });

        this.close_request.connect (e => {
            return before_destroy ();
        });
    }

    private void build_reminder_editor () {
        this.reminder_editor = new Reminduck.Views.ReminderEditor ();

        this.reminder_editor.reminder_created.connect ((new_reminder) => {
            ReminduckApp.reload_reminders ();
            show_reminders_view ();
        });

        this.reminder_editor.reminder_edited.connect ((edited_file) => {
            ReminduckApp.reload_reminders ();
            show_reminders_view ();
        });

        this.reminder_editor.reminder_deleted.connect (on_reminder_deleted);
        stack.add_named (this.reminder_editor, "reminder_editor");
    }

    private void build_reminders_view () {
        this.reminders_view = new Reminduck.Views.RemindersView ();

        this.reminders_view.add_request.connect (() => {
            show_reminder_editor ();
        });

        this.reminders_view.edit_request.connect ((reminder) => {
            show_reminder_editor (reminder);
        });

        this.reminders_view.reminder_deleted.connect (on_reminder_deleted);
        stack.add_named (this.reminders_view, "reminders_view");
    }

    private void build_settings_view () {
        this.settings_view = new Reminduck.Views.SettingsView ();
        stack.add_named (this.settings_view, "settings_view");
    }

    public void show_reminder_editor (Reminder? reminder = null) {
        stack.set_transition_type (Gtk.StackTransitionType.SLIDE_LEFT);
        stack.set_visible_child_name ("reminder_editor");
        back_revealer.reveal_child = true;
        this.reminder_editor.edit_reminder (reminder);
    }

    private void show_reminders_view (Gtk.StackTransitionType slide = Gtk.StackTransitionType.SLIDE_RIGHT) {
        stack.set_transition_type (slide);
        stack.set_visible_child_name ("reminders_view");
        this.reminders_view.build_reminders_list ();
        back_revealer.reveal_child = true;
        this.reminder_editor.reset_fields ();
    }

    public void show_welcome_view (Gtk.StackTransitionType slide = Gtk.StackTransitionType.SLIDE_RIGHT) {
        ReminduckApp.reload_reminders ();

        if (ReminduckApp.reminders.size > 0) {
            welcome_view.reminders_view_button.show ();
        } else {
            welcome_view.reminders_view_button.hide ();
        }

        stack.set_transition_type (slide);
        stack.set_visible_child_name ("welcome");
        back_revealer.reveal_child = false;
        this.reminder_editor.reset_fields ();
    }

    private void show_settings_view (Gtk.StackTransitionType slide = Gtk.StackTransitionType.SLIDE_RIGHT) {
        stack.set_transition_type (slide);
        stack.set_visible_child_name ("settings_view");
        back_revealer.reveal_child = true;
    }

    private void on_reminder_deleted () {
        ReminduckApp.reload_reminders ();
        if (ReminduckApp.reminders.size == 0) {
            show_welcome_view ();
        } else {
            this.reminders_view.build_reminders_list ();
        }
    }

    private bool before_destroy () {
        int width, height;

        get_default_size (out width, out height);

        this.settings.set_int ("window-width", width);
        this.settings.set_int ("window-height", height);

        hide ();
        return true;
    }
}
