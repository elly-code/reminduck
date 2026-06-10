/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText:  2011-2019 Matheus Fantinel
 *                          2025 Stella & Charlie (teamcons.carrd.co)
 *                          2025 Contributions from the ellie_Commons community (github.com/ellie-commons/)
 */

namespace Reminduck.Utils {

#if WINDOWS
        private static string? get_windows_startup_path () {
            unowned string? appdata = Environment.get_variable ("APPDATA");
            if (appdata == null || appdata == "") {
                return null;
            }

            return Path.build_filename (
                appdata,
                "Microsoft",
                "Windows",
                "Start Menu",
                "Programs",
                "Startup",
                "Reminduck.vbs"
            );
        }

        private static string get_windows_launcher_path () {
            string install_dir = Win32.get_package_installation_directory_of_module (null);
            string launcher = Path.build_filename (install_dir, "Reminduck.bat");

            if (FileUtils.test (launcher, FileTest.EXISTS)) {
                return launcher;
            }

            var parent = File.new_for_path (install_dir).get_parent ();
            if (parent != null) {
                launcher = Path.build_filename (parent.get_path (), "Reminduck.bat");
            }

            return launcher;
        }

        private static string escape_vbs_string (string value) {
            return value.replace ("\"", "\"\"");
        }
#endif

        private static void request_autostart () {
#if WINDOWS
            string? startup_path = get_windows_startup_path ();
            if (startup_path == null) {
                warning ("Unable to find Windows startup folder");
                return;
            }

            string launcher = escape_vbs_string (get_windows_launcher_path ());
            string contents = "Set WshShell = CreateObject(\"WScript.Shell\")\r\n" +
                "WshShell.Run \"\"\"" + launcher + "\"\" --headless\", 0, False\r\n";

            try {
                DirUtils.create_with_parents (Path.get_dirname (startup_path), 0755);
                FileUtils.set_contents (startup_path, contents);
                stdout.printf ("\nRequested autostart");
            } catch (Error e) {
                warning ("Unable to request Windows autostart: %s", e.message);
            }
#else
            Xdp.Portal portal = new Xdp.Portal ();
            GenericArray<weak string> cmd = new GenericArray<weak string> ();
            cmd.add ("io.github.elly_code.reminduck");
            cmd.add ("--headless");

            portal.request_background.begin (
                null,
                _("Autostart Reminduck in background to send reminders"),
                cmd,
                Xdp.BackgroundFlags.AUTOSTART,
                null);

            stdout.printf ("\n🚀 Requested autostart");
#endif
        }

        private static void remove_autostart () {
#if WINDOWS
            string? startup_path = get_windows_startup_path ();
            if (startup_path == null) {
                warning ("Unable to find Windows startup folder");
                return;
            }

            if (FileUtils.test (startup_path, FileTest.EXISTS)) {
                FileUtils.remove (startup_path);
            }

            stdout.printf ("\nRemoved autostart");
#else
            Xdp.Portal portal = new Xdp.Portal ();
            GenericArray<weak string> cmd = new GenericArray<weak string> ();
            cmd.add ("io.github.elly_code.reminduck");
            cmd.add ("--headless");

            portal.request_background.begin (
                null,
                _("Remove Reminduck from autostart"),
                cmd,
                Xdp.BackgroundFlags.NONE,
                null);

            stdout.printf ("\n🚀 Removed autostart");
#endif
        }
}
