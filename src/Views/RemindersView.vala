/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText:  2011-2019 Matheus Fantinel
 *                          2025 Stella & Charlie (teamcons.carrd.co)
 *                          2025 Contributions from the ellie_Commons community (github.com/ellie-commons/)
 */


using Gee;

/**
 * A giant list generated from reminders saved in the Database
 */
public class Reminduck.Views.RemindersView : Gtk.Box {
        public signal void add_request ();
        public signal void edit_request (Reminder reminder);
        public signal void reminder_deleted ();

        Gtk.Label title;
        Gtk.ListBox reminders_list;

        construct {
            orientation = Gtk.Orientation.VERTICAL;
            valign = Gtk.Align.FILL;
            hexpand = vexpand = true;
            margin_start = 24;
            margin_end = 24;

            title = new Gtk.Label (_("Your reminders")) {
                margin_top = 24,
                margin_bottom = 12
            };
            title.add_css_class (Granite.STYLE_CLASS_H2_LABEL);

            append (this.title);

            var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 12);

            var add_new_button = new Gtk.Button.with_label (_("Create another"));
            add_new_button.halign = Gtk.Align.CENTER;
            add_new_button.add_css_class (Granite.STYLE_CLASS_SUGGESTED_ACTION);
            add_new_button.activate.connect (add_reminder);
            add_new_button.clicked.connect (add_reminder);

            box.append (add_new_button);

            var scrolled_window = new Gtk.ScrolledWindow () {
                vexpand = true,
                valign = Gtk.Align.FILL,
            };

            build_reminders_list ();

            scrolled_window.set_child (this.reminders_list);
            box.append (scrolled_window);

            append (box);


        }

        public void add_reminder () {
            add_request ();
        }

        public void build_reminders_list () {
            if (this.reminders_list == null) {
                this.reminders_list = new Gtk.ListBox ();
                this.reminders_list.add_css_class ("reminduck-reminders-list");
            } else {
                this.reminders_list.remove_all ();
            }

            var index = 0;
            foreach (var reminder in ReminduckApp.reminders) {
                var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
                box.margin_top = 2;
                box.add_css_class ("list-item");

                if (reminder.recurrency_type != RecurrencyType.NONE) {
                    var recurrency_indicator = new Gtk.Image ();
                    recurrency_indicator.gicon = new ThemedIcon ("media-playlist-repeat");
                    recurrency_indicator.pixel_size = 18;

                    string tooltip = reminder.recurrency_type.to_friendly_string (reminder.recurrency_interval);
                    if (reminder.recurrency_type == RecurrencyType.EVERY_WEEK && reminder.weekdays != 0) {
                        tooltip += " (%s)".printf (Weekdays.to_display_string (reminder.weekdays));
                    }
                    recurrency_indicator.tooltip_text = tooltip;
                    box.append (recurrency_indicator);
                }

                var description = new Gtk.Label (reminder.description) {
                    hexpand = true,
                    halign = Gtk.Align.START
                };
                description.wrap = true;
                description.single_line_mode = false;

                box.append (description);

                string date_label_text = "";
                var is_today = reminder.time.format ("%x") == new GLib.DateTime.now ().format ("%x");
                if (is_today) {
                    date_label_text += _("Today");
                } else {
                    date_label_text += reminder.time.format ("%x");
                }

                var time_text_split = reminder.time.format ("%X").split (":");

                date_label_text += " " + time_text_split[0].concat (":", time_text_split[1]);

                box.append (new Gtk.Label (date_label_text));

                var edit_button = new Gtk.Button.from_icon_name ("edit");
                edit_button.tooltip_text = _("Edit");
                edit_button.activate.connect (() => { on_edit (reminder); } );
                edit_button.clicked.connect (() => { on_edit (reminder); } );

                box.append (edit_button);

                var delete_button = new Gtk.Button.from_icon_name ("edit-delete");
                delete_button.tooltip_text = _("Delete");
                delete_button.activate.connect (() => { on_delete (reminder); } );
                delete_button.clicked.connect (() => { on_delete (reminder); } );

                box.append (delete_button);

                var row = new Gtk.ListBoxRow ();
                row.set_child (box);

                this.reminders_list.insert (row, index);
            }
            index++;

            this.reminders_list.show ();
        }

        private void on_delete (Reminder reminder) {
            ReminduckApp.database.delete_reminder (reminder.rowid);
            this.reminder_deleted ();
        }

        private void on_edit (Reminder reminder) {
            this.edit_request (reminder);
        }
}
