/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText:  2011-2019 Matheus Fantinel
 *                          2025 Stella & Charlie (teamcons.carrd.co)
 *                          2025 Contributions from the ellie_Commons community (github.com/ellie-commons/)
 */

 /**
 * An object playing a sound upon creation
 */
public class Reminduck.Quack : Object {
    public signal void started ();
    public signal void ended ();

    public Quack (QuackType? type = QuackType.DEFAULT) {
        var mediafile = Gtk.MediaFile.for_resource (type.to_resource_path ());

        mediafile.notify["prepared"].connect (() => {
            var t = mediafile.duration;
            var s = t / 1000000;
            var ms = t % 1000000;
            print ("Play for %jd.%06jd\n", s, ms);
            started ();
        });

        mediafile.notify["ended"].connect (() => {
            print ("stream ended %s\n", mediafile.ended.to_string ());
            ended ();
        });

        mediafile.play ();
    }
}

/**
 * Allows specifying which sound to play (NOT IMPLEMENTED YET)
 */
public enum Reminduck.QuackType {
    DEFAULT,
    PLASTIC,
    HORDE,
    CYBER,
    RANDOM;

    public string to_resource_path () {
        switch (this) {
            case DEFAULT: return "/io/github/ellie_commons/reminduck/default_quack.ogg";
            case PLASTIC: return "/io/github/ellie_commons/reminduck/plastic_quack.ogg";
            case RANDOM: return random ().to_resource_path ();
            default: return "/io/github/ellie_commons/reminduck/quack.ogg";
        }
    }

    public string to_friendly_name () {
        switch (this) {
            case DEFAULT: return _("Default Duck");
            case PLASTIC: return _("Plastic Duck");
            case RANDOM: return _("Random Duck");
            default: return _("Default Duck");
        }
    }

    public static string[] choices () {
        return {
            DEFAULT.to_friendly_name (),
            PLASTIC.to_friendly_name (),
            RANDOM.to_friendly_name ()
        };
    }

    private static QuackType random () {
        QuackType[] possibilities = {
            DEFAULT,
            PLASTIC
        };
        return possibilities[Random.int_range (0, possibilities.length)];
    }
}