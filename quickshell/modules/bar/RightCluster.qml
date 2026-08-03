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

    // Media
    Pill {
        Music {}
        Separator {}
        Ambiance {}
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
