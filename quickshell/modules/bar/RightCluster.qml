pragma ComponentBehavior: Bound
import QtQuick
import qs.modules.bambu

// Mirrors the old i3status-rust config.toml (full) / config_short.toml
// (short) split, now grouped into pills by rough category instead of one
// flat row: Media / Tasks / System / Connectivity / Status / Clock / Tray.
// Per-widget full/short gating is preserved exactly as it was before the
// regroup (see comments) even though several are currently disabled.
Row {
    id: root

    required property bool full
    required property bool showTray

    spacing: 8

    // Media - pill collapses fully when both are silent. Ambiance stays
    // visible whenever Music is (so its icon rides along next to the
    // track), and independently whenever ambiance itself is playing (so
    // it's always clickable to stop); Separator only shows alongside Music
    // since Ambiance's own visibility is a superset of Music's.
    Pill {
        Music { id: musicWidget }

        Loader {
            active: root.full
            sourceComponent: Pill {
                Separator { visible: musicWidget.visible }
                Ambiance {
                    id: ambianceWidget
                    visible: ambianceWidget.playing || musicWidget.visible
                }
            }
        }
    }

    // Tasks / background sync - full-bar only (Pomodoro was previously
    // ungated/shown on both bars; if re-enabled, give it its own pill
    // instead of putting it here, or it'll disappear from the short bar).
    Loader {
        active: root.full
        sourceComponent: Pill {
            Syncthing {}
            Separator {}
            VaultSync {}
        }
    }

    // Status - Bambu collapses to nothing whenever the printer isn't
    // actively printing/paused (same convention as Music with nothing
    // playing), so this pill only ever appears while a print is running.
    Pill {
        Bambu {}
    }

    Pill {
        Stator {}
    }

    // System - re-enabling Hueshift/DiskIo below needs a Separator {} added
    // next to them too, same as the three active widgets here.
    Pill {
        // Loader { active: root.full; sourceComponent: Hueshift {} }
        AmdGpu {
            full: root.full
        }
        Separator {}
        Cpu {
            full: root.full
        }
        Separator {}
        Memory {
            full: root.full
        }
        // Loader { active: root.full; sourceComponent: DiskIo {} }
    }

    // Dev boards - collapses to nothing whenever no ttyUSB*/ttyACM* device
    // is attached, same convention as the Bambu pill above.
    Pill {
        SerialWatcher {}
    }

    // Connectivity
    Pill {
        Network {}
        Separator {}
        Loader {
            active: root.full
            sourceComponent: Row {
                spacing: 10
                Bluetooth {}
                Separator {}
            }
        }
        Sound {}
    }

    // Structural theme
    Pill {
        ThemeSwitcherWidget {}
        Separator {}
        DesktopWidgetToggle {}
    }

    // Utils
    Loader {
        active: root.full
        sourceComponent: Pill {
            spacing: 10
            DrawToggle {}
            Separator {}
            ReticleToggle {}
            Separator {}
            ColorPicker {}
            Separator {}
            UnitTools {}
        }
    }

    // Clock
    Pill {
        Clock {
            full: root.full
        }
    }

    // Tray
    Loader {
        active: root.showTray
        sourceComponent: Pill {
            Tray {}
            Separator {}
            NotificationBell {}
        }
    }
}
