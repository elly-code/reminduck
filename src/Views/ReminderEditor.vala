/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText:  2011-2019 Matheus Fantinel
 *                          2025 Stella & Charlie (teamcons.carrd.co)
 *                          2025 Contributions from the ellie_Commons community (github.com/ellie-commons/)
 */

/**
 * A simple view allowing to set a specific reminder.
 * The object is then passed on to database
 */
public class Reminduck.Views.ReminderEditor : Gtk.Box {
    public signal void reminder_created ();
    public signal void reminder_edited ();
    public signal void reminder_deleted ();

    Gtk.Label title;
    Gtk.Entry reminder_input;
    Granite.DatePicker date_picker;
    Granite.TimePicker time_picker;
    Reminduck.RepeatBox repeatbox;
    Gtk.Switch persist_toggle;

    Gtk.Button delete_button;
    Gtk.Button save_button;

    Reminder reminder;

    bool touched;

    construct {
        orientation = Gtk.Orientation.VERTICAL;
        valign = Gtk.Align.FILL;
        hexpand = vexpand = true;
        margin_start = 24;
        margin_end = 24;
        reminder = new Reminder ();

        title = new Gtk.Label ("") {
            margin_top = 24,
            margin_bottom = 12
        };
        title.add_css_class (Granite.STYLE_CLASS_H2_LABEL);

        reminder_input = new Gtk.Entry () {
            placeholder_text = _("What do you want to be reminded of?"),
            show_emoji_icon = true
        };

        date_picker = new Granite.DatePicker.with_format (
            Granite.DateTime.get_default_date_format (false, true, true)
        );

        time_picker = new Granite.TimePicker.with_format (
            Granite.DateTime.get_default_time_format (true),
            Granite.DateTime.get_default_time_format (false)
        );

        var date_time_container = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        date_time_container.append (date_picker);
        date_time_container.append (time_picker);

        var fields_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 12) {
            valign = Gtk.Align.CENTER,
            vexpand = true
        };
        fields_box.append (reminder_input);
        fields_box.append (date_time_container);

        var repeat_label = new Gtk.Label (_("Repeat")) {
            margin_top = 6,
            halign = Gtk.Align.START
        };
        repeat_label.add_css_class (Granite.STYLE_CLASS_H4_LABEL);

        fields_box.append (repeat_label);
        repeatbox = new Reminduck.RepeatBox ();

        fields_box.append (repeatbox);

        /* ---------------- PERSISTENT TOGGLE ---------------- */
        var persist_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12) {
            margin_top = 6,
            halign = Gtk.Align.FILL,
            hexpand = true
        };

        persist_toggle = new Gtk.Switch () {
            valign = Gtk.Align.CENTER,
            active = false
        };

        var persist_label = new Gtk.Label (_("Persistent notification")) {
            halign = Gtk.Align.START,
            hexpand = true
        };
        persist_label.add_css_class (Granite.STYLE_CLASS_H4_LABEL);

        var persist_hint = new Gtk.Label (_("If enabled, the reminder will stay until dismissed")) {
            halign = Gtk.Align.START,
            hexpand = true
        };
        persist_hint.add_css_class (Granite.STYLE_CLASS_DIM_LABEL);

        var persist_label_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 2);
        persist_label_box.append (persist_label);
        persist_label_box.append (persist_hint);

        persist_box.append (persist_label_box);
        persist_box.append (persist_toggle);

        fields_box.append (persist_box);

        var buttons = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12) {
            halign = Gtk.Align.END,
            margin_top = 12
        };

        delete_button = new Gtk.Button.with_label (_("Delete"));
        delete_button.add_css_class (Granite.STYLE_CLASS_DESTRUCTIVE_ACTION);

        save_button = new Gtk.Button.with_label (_("Save reminder")) {
            sensitive = false
        };
        save_button.add_css_class (Granite.STYLE_CLASS_SUGGESTED_ACTION);

        buttons.append (delete_button);
        buttons.append (save_button);

        fields_box.append (buttons);

        append (title);
        append (fields_box);

        save_button.grab_focus ();

        /* ---------------- CONNECTS AND BINDS ---------------- */
        delete_button.clicked.connect (on_delete);
        save_button.clicked.connect (on_save);

        this.reminder_input.changed.connect (() => {
            this.touched = true;
            this.validate ();
        });

        this.reminder_input.activate.connect (() => {
            this.save_button.clicked ();
        });

        this.date_picker.changed.connect (() => {this.validate ();});
        this.time_picker.changed.connect (() => {this.validate ();});
    }

    public bool validate () {
        var result = true;

        if (this.reminder_input.text == null || this.reminder_input.text.chomp () == "") {
            if (this.touched) {
                this.reminder_input.add_css_class (Granite.STYLE_CLASS_ERROR);
            }

            save_button.sensitive = false;
            result = false;

        } else {
            this.reminder_input.remove_css_class (Granite.STYLE_CLASS_ERROR);
        }

        var datetime = this.mount_datetime (this.date_picker.date, this.time_picker.time);

        if (datetime.compare (new GLib.DateTime.now_local ()) <= 0) {
            date_picker.add_css_class (Granite.STYLE_CLASS_ERROR);
            time_picker.add_css_class (Granite.STYLE_CLASS_ERROR);

            save_button.sensitive = false;
            result = false;
        } else {
            date_picker.remove_css_class (Granite.STYLE_CLASS_ERROR);
            time_picker.remove_css_class (Granite.STYLE_CLASS_ERROR);
        }

        if (result) {
            save_button.sensitive = true;
        }

        return result;
    }

    public void edit_reminder (Reminder? existing_reminder) {
        if (existing_reminder != null) {

            reminder = existing_reminder;

            reminder_input.text = reminder.description;
            date_picker.date = reminder.time;
            time_picker.time = reminder.time;

            repeatbox.recurrency_type = reminder.recurrency_type;

            if (reminder.recurrency_type != RecurrencyType.NONE) {
                repeatbox.interval = reminder.recurrency_interval;
            }

            repeatbox.weekdays = reminder.weekdays;
            persist_toggle.active = reminder.persistent;

            title.label = _("Edit reminder");
            delete_button.visible = true;

        } else {
            reminder = new Reminder ();
            title.label = _("Create a new reminder");
            delete_button.visible = false;
            reset_fields ();
        }
    }

    private void on_delete () {
        ReminduckApp.database.delete_reminder (reminder.rowid);
        reminder_deleted ();
        reminder_edited ();
    }

    public void reset_fields () {
        reminder_input.text = "";
        date_picker.date = new GLib.DateTime.now_local ().add_minutes (15);
        time_picker.time = this.date_picker.date;
        repeatbox.reset ();
        persist_toggle.active = false;
    }

    private void on_save () {
        if (validate ()) {
            reminder.description = reminder_input.text;
            reminder.time = mount_datetime (date_picker.date, time_picker.time);
            reminder.recurrency_type = repeatbox.recurrency_type;
            reminder.recurrency_interval = (int)repeatbox.interval;
            reminder.persistent = persist_toggle.active;
            reminder.weekdays = repeatbox.weekdays;

            var result = ReminduckApp.database.upsert_reminder (reminder);

            if (result) {
                reminder_created ();
            } else {
                reminder_edited ();
            }
        }
    }

    private DateTime mount_datetime (DateTime date, DateTime time) {
        return new GLib.DateTime.local (
            date.get_year (),
            date.get_month (),
            date.get_day_of_month (),
            time.get_hour (),
            time.get_minute (),
            0
        );
    }
}
