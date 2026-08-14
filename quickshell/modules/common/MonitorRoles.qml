pragma Singleton
import QtQuick
import Quickshell

// Single source of truth for which output plays which role. DP-1 (the
// portrait monitor) is the only output ever special-cased by name; whichever
// other monitor is active - DP-2 in the normal dual layout, HDMI-A-1 when
// running solo (see toggle-monitors) - is treated as primary. This avoids
// hardcoding "DP-2" across the bar and the desktop/reticle/draw overlays, all
// of which used to each hardcode their own copy of that name.
Singleton {
    readonly property string secondaryOutput: "DP-1"

    function isSecondary(screen) {
        return !!screen && screen.name === secondaryOutput;
    }

    function primaryScreen() {
        return Quickshell.screens.find(s => s.name !== secondaryOutput) ?? Quickshell.screens[0];
    }
}
