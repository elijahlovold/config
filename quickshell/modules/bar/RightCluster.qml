pragma ComponentBehavior: Bound
import QtQuick

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
        Separator { visible: musicWidget.visible }
        Ambiance {
            id: ambianceWidget
            visible: ambianceWidget.playing || musicWidget.visible
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

    // Status
    Loader {
        active: root.full
        sourceComponent: Pill {
            Stator {}
        }
    }

    // System - re-enabling Hueshift/DiskIo below needs a Separator {} added
    // next to them too, same as the three active widgets here.
    Pill {
        // Loader { active: root.full; sourceComponent: Hueshift {} }
        AmdGpu {}
        Separator {}
        Cpu {}
        Separator {}
        Memory {}
        // Loader { active: root.full; sourceComponent: DiskIo {} }
    }

    // Connectivity
    Pill {
        Network {}
        Separator {}
        Bluetooth {}
        Separator {}
        Sound {}
    }

    // Clock
    Pill {
        DesktopWidgetToggle {}
        Separator {}
        Clock {
            full: root.full
        }
    }

    // Tray
    Loader {
        active: root.showTray
        sourceComponent: Pill {
            Tray {}
        }
    }
}
