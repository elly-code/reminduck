/*
* Copyright(c) 2011-2019 Matheus Fantinel
* Copyright (c) 2025 Stella, Charlie, (teamcons on GitHub) and the Ellie_Commons community
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or(at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
* Authored by: Matheus Fantinel <matfantinel@gmail.com>
*/

namespace Reminduck {
    public class ReminduckApp : Gtk.Application {
        public static Gee.ArrayList<Reminduck.Reminder> reminders;
        public bool headless = false;
        public bool ask_autostart = false;
        private uint timeout_id = 0;
        public bool new_reminder = false;

        public Granite.Settings granite_settings;
        public Gtk.Settings gtk_settings;
        public static GLib.Settings settings;

        public MainWindow main_window { get; private set; default = null; }
        public static Reminduck.Database database;
   
        public ReminduckApp () {
            Object (
                application_id: "io.github.ellie_commons.reminduck",
                flags: ApplicationFlags.HANDLES_COMMAND_LINE
            );
        }

        construct {
            // Init internationalization support
            Intl.setlocale (LocaleCategory.ALL, "");
            Intl.bindtextdomain (GETTEXT_PACKAGE, LOCALEDIR);
            Intl.bind_textdomain_codeset (GETTEXT_PACKAGE, "UTF-8");
            Intl.textdomain (GETTEXT_PACKAGE);

            var quit_action = new SimpleAction ("quit", null);
            add_action (quit_action);
            set_accels_for_action ("app.quit", {"<Control>q"});
            quit_action.activate.connect (quit);

            database = new Reminduck.Database();
        }

        public override void startup () {
            base.startup ();
            Gtk.init ();
            Granite.init ();

            // Follow dark and light, use bananana
            granite_settings = Granite.Settings.get_default ();
            gtk_settings = Gtk.Settings.get_default ();
            gtk_settings.gtk_icon_theme_name = "elementary";
            gtk_settings.gtk_theme_name =   "io.elementary.stylesheet.banana";

            gtk_settings.gtk_application_prefer_dark_theme = (
	                granite_settings.prefers_color_scheme == DARK
                );
	
            granite_settings.notify["prefers-color-scheme"].connect (() => {
                gtk_settings.gtk_application_prefer_dark_theme = (
                        granite_settings.prefers_color_scheme == DARK
                    );
            });

            settings = new GLib.Settings ("io.github.ellie_commons.reminduck.state");

            // On first run, request autostart
            if (settings.get_boolean ("first-run") || ask_autostart) {

                // Show first run message only if really first run
                if (settings.get_boolean ("first-run")) {
                    stdout.printf ("\n🎉️ First run");
                    settings.set_boolean ("first-run", false);
                } else {
                    ask_autostart = false;
                }

                Reminduck.Utils.request_autostart ();
            }

            var plsbump = false;
            if (!settings.get_boolean ("bumped")) {
                plsbump = true;
                settings.set_boolean ("bumped", true);
            }

            database.verify_database (plsbump);
        }

        public static int main(string[] args) {
            return new ReminduckApp ().run (args);
        }

        protected override void activate () {
            stdout.printf ("\n✔️ Activated");

            reload_reminders ();

            if (this.main_window == null) {

                this.main_window = new MainWindow ();
                this.main_window.set_application (this);                

                if (!this.headless) {
                    this.main_window.show ();

                    if (this.new_reminder) {
                        this.main_window.show_reminder_editor ();

                    } else {
                        this.main_window.show_welcome_view (Gtk.StackTransitionType.NONE);                        
                    }

                    this.main_window.present ();
                }
            }
            
            if (this.main_window != null && !this.headless) {
                    this.main_window.show ();
                    if (this.new_reminder) {
                        this.main_window.show_reminder_editor ();

                    } else {
                        this.main_window.show_welcome_view (Gtk.StackTransitionType.NONE);                        
                    }
                    this.main_window.present ();
            }

            if (timeout_id == 0) {
                set_reminder_interval ();
            }
        }
        
        public override int command_line (ApplicationCommandLine command_line) {
            stdout.printf ("\n💲️ Command line mode started");
    
            bool headless_mode = false;
            bool switch_new_reminder = false;

            OptionEntry[] options = new OptionEntry[3];
            options[0] = {
                "headless", 0, 0, OptionArg.NONE,
                ref headless_mode, "Run without window", null
            };
            options[1] = {
                "request-autostart", 0, 0, OptionArg.NONE,
                ref ask_autostart, "Request autostart permission", null
            };
            options[2] = {
                "new-reminder", 0, 0, OptionArg.NONE,
                ref switch_new_reminder, "Immediately jump to reminder editor", null
            };
    
            // We have to make an extra copy of the array, since .parse assumes
            // that it can remove strings from the array without freeing them.
            string[] args = command_line.get_arguments ();
            string[] _args = new string[args.length];
            for (int i = 0; i < args.length; i++) {
                _args[i] = args[i];
            }
    
            try {
                var ctx = new OptionContext ();
                ctx.set_help_enabled (true);
                ctx.add_main_entries (options, null);
                unowned string[] tmp = _args;
                ctx.parse(ref tmp);
            } catch (OptionError e) {
                command_line.print ("error: %s\n", e.message);
                return 0;
            }
    
            this.headless = headless_mode;
            this.new_reminder = switch_new_reminder;

            stdout.printf(this.headless ? "\n✔️ Headless" : "\n️️️️ ✔️ Interface");

            activate ();
            return 0;
        }


        public static void reload_reminders () {
            reminders = database.fetch_reminders ();
        }

        public void set_reminder_interval() {
            // Disable old timer to avoid repeated notifications
            if (timeout_id > 0) {
                Source.remove(timeout_id);
            }

            timeout_id = Timeout.add_seconds (1 * 60, remind);
        }
    
        public bool remind () {
            reload_reminders ();
            
            Gee.ArrayList<string> reminders_to_delete = new Gee.ArrayList<string> ();
            foreach(var reminder in reminders) {

                //If reminder date < current date
                if (reminder.time.compare (new GLib.DateTime.now ()) <= 0) {
                    var notification = new Notification (_("QUACK!"));
                    notification.set_body (reminder.description);

                    if (settings.get_boolean ("persistent")) {
                        notification.set_priority (GLib.NotificationPriority.URGENT);
                    } else {
                        notification.set_priority (GLib.NotificationPriority.NORMAL);
                    }

                    this.send_notification ("notify.app", notification);

                    if (settings.get_boolean("quack-sound")) {
                        new Reminduck.Quack();
                    }

                    if (reminder.recurrency_type != RecurrencyType.NONE) {
                        GLib.DateTime new_time = reminder.time;

                        //In case the user hasn't used his computer for a while, recurrent reminders
                        //May have not fired for a while. Instead of bombarding him with notifications,
                        //Let's make sure our new date is in the future

                        //Let's try it only 30 times - no need to risk an infinite loop
                        for (var i = 0; i < 30; i++) {
                            switch (reminder.recurrency_type) {
                                case RecurrencyType.EVERY_X_MINUTES:
                                    new_time = reminder.time.add_minutes (reminder.recurrency_interval);
                                    break;

                                case RecurrencyType.EVERY_X_HOURS:
                                    new_time = reminder.time.add_hours (reminder.recurrency_interval); 
                                    break;

                                case RecurrencyType.EVERY_DAY:
                                    new_time = reminder.time.add_days (reminder.recurrency_interval);
                                    break;
                                case RecurrencyType.EVERY_WEEK:
                                    new_time = reminder.time.add_weeks (reminder.recurrency_interval);
                                    break;
                                case RecurrencyType.EVERY_MONTH:
                                    new_time = reminder.time.add_months (reminder.recurrency_interval);
                                    break;
                                default:
                                    break;
                            }

                            //if new_time > current time
                            if (new_time.compare (new GLib.DateTime.now ()) > 0) {
                                var new_reminder = new Reminder();
                                new_reminder.time = new_time;
                                new_reminder.description = reminder.description;
                                new_reminder.recurrency_type = reminder.recurrency_type;
                                new_reminder.recurrency_interval = reminder.recurrency_interval;

                                database.upsert_reminder (new_reminder);
                                break;
                            }
                            //else, keep looping
                        }
                    }

                    reminders_to_delete.add (reminder.rowid);
                }
            }

            if (reminders_to_delete.size > 0) {
                foreach(var reminder in reminders_to_delete) {
                    database.delete_reminder (reminder);
                }
                reload_reminders ();
            }

            return true;
        }
    }
}
