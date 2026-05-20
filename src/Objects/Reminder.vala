/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText:  2011-2019 Matheus Fantinel
 *                          2025 Stella & Charlie (teamcons.carrd.co)
 *                          2025 Contributions from the ellie_Commons community (github.com/ellie-commons/)
 */

namespace Reminduck {
    public class Reminder : GLib.Object {
        public string rowid { get; set; }
        public string description { get; set; }
        public GLib.DateTime time { get; set; }
        public RecurrencyType recurrency_type { get; set; default = RecurrencyType.NONE; }
        public int recurrency_interval { get; set; }
        public bool persistent { get; set; default = false; }
        public int weekdays { get; set; default = 0; }
    }

    public enum RecurrencyType {
        EVERY_X_MINUTES,
        EVERY_X_HOURS,
        EVERY_DAY,
        EVERY_WEEK,
        EVERY_MONTH,
        EVERY_YEAR,
        NONE;

        public string to_friendly_string (int? interval = 0) {
            switch (this) {
                ///TRANSLATORS: [0] is singular form, [1] is plural form. These are displayed as menu items
                case NONE: return _("Don't Repeat");
                case EVERY_X_MINUTES: return GLib.ngettext ("Minute", "Minutes", interval);
                case EVERY_X_HOURS: return GLib.ngettext ("Hour", "Hours", interval);
                case EVERY_DAY: return GLib.ngettext ("Day", "Days", interval);
                case EVERY_WEEK: return GLib.ngettext ("Week", "Weeks", interval);
                case EVERY_MONTH: return GLib.ngettext ("Month", "Months", interval);
                case EVERY_YEAR: return GLib.ngettext ("Year", "Years", interval);
                default: assert_not_reached ();
            }
        }

        public static string[] choices (int? interval = 0) {
            return {
                RecurrencyType.EVERY_X_MINUTES.to_friendly_string (interval),
                RecurrencyType.EVERY_X_HOURS.to_friendly_string (interval),
                RecurrencyType.EVERY_DAY.to_friendly_string (interval),
                RecurrencyType.EVERY_WEEK.to_friendly_string (interval),
                RecurrencyType.EVERY_MONTH.to_friendly_string (interval),
                RecurrencyType.EVERY_YEAR.to_friendly_string (interval)
            };
        }
    }

    /**
     * Helper for weekdays bitmask
     */
    public static class Weekdays {
        public const int MONDAY    = 1 << 0;
        public const int TUESDAY   = 1 << 1;
        public const int WEDNESDAY = 1 << 2;
        public const int THURSDAY  = 1 << 3;
        public const int FRIDAY    = 1 << 4;
        public const int SATURDAY  = 1 << 5;
        public const int SUNDAY    = 1 << 6;

        public static string[] day_names () {
            return {
                _("Monday"),
                _("Tuesday"),
                _("Wednesday"),
                _("Thursday"),
                _("Friday"),
                _("Saturday"),
                _("Sunday")
            };
        }

        public static int day_from_string (string day) {
            switch (day) {
                case "Monday": return MONDAY;
                case "Tuesday": return TUESDAY;
                case "Wednesday": return WEDNESDAY;
                case "Thursday": return THURSDAY;
                case "Friday": return FRIDAY;
                case "Saturday": return SATURDAY;
                case "Sunday": return SUNDAY;
                default: return 0;
            }
        }

        public static bool is_set (int bitmask, int day) {
            return (bitmask & day) != 0;
        }

        public static int toggle (int bitmask, int day) {
            return bitmask ^ day;
        }

        public static string to_display_string (int bitmask) {
            if (bitmask == 0) return _("No days selected");

            string[] names = day_names ();
            int[] flags = { MONDAY, TUESDAY, WEDNESDAY, THURSDAY, FRIDAY, SATURDAY, SUNDAY };
            string[] selected = {};

            for (int i = 0; i < flags.length; i++) {
                if ((bitmask & flags[i]) != 0) {
                    selected += names[i];
                }
            }

            if (selected.length == 7) {
                return _("Every day");
            } else if (selected.length == 5 &&
                       (bitmask & (SATURDAY | SUNDAY)) == 0) {
                return _("Weekdays");
            } else if (selected.length == 2 &&
                       (bitmask & (SATURDAY | SUNDAY)) == (SATURDAY | SUNDAY)) {
                return _("Weekends");
            }

            return string.joinv (", ", selected);
        }

        /**
         * Get the next DateTime matching the given weekdays bitmask,
         * starting from the given time.
         */
        public static DateTime next_matching_day (DateTime from, int bitmask) {
            if (bitmask == 0) return from;

            var candidate = from;
            for (int i = 0; i < 7; i++) {
                int day_of_week = candidate.get_day_of_week (); // 1=Mon, 7=Sun
                int flag = 1 << (day_of_week - 1);
                if ((bitmask & flag) != 0) {
                    return candidate;
                }
                candidate = candidate.add_days (1);
            }
            return from;
        }
    }
}
