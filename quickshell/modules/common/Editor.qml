pragma Singleton
import QtQuick
import Quickshell

// Generic "open a file at a line number in a terminal editor" helper, so any
// widget that wants to jump the user to a source location (e.g. Keybinds
// jumping to a bind's line in keybinds.lua) shares one place to change the
// terminal/editor pair, instead of each widget hardcoding its own.
Singleton {
    function openAtLine(filePath, line) {
        const args = ["alacritty", "-e", "nvim"];
        if (line)
            args.push("+" + line);
        args.push(filePath);
        Quickshell.execDetached(args);
    }
}
