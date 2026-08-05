.pragma library

// Shared data/helpers for the Keybinds overlay. Consumed by KeybindService
// (parsing `hyprctl binds -j`) and KeyboardGrid.

// ---- Modifier mask bits (standard X11/Hyprland modmask) ----
function modsFromMask(mask) {
    const mods = [];
    if (mask & 64)
        mods.push("Super");
    if (mask & 1)
        mods.push("Shift");
    if (mask & 4)
        mods.push("Ctrl");
    if (mask & 8)
        mods.push("Alt");
    return mods;
}

// ---- key id normalization, for matching a raw hyprctl `key` string to a
// physical-layout slot regardless of case (top-level binds use "H", the
// resize submap binds the bare lowercase "h" - same physical key). ----
const KEY_ID_ALIASES = {
    "left": "Left",
    "right": "Right",
    "up": "Up",
    "down": "Down",
    "return": "Return",
    "enter": "Return",
    "kp_enter": "Return",
    "escape": "Escape",
    "esc": "Escape",
    "tab": "Tab",
    "print": "Print",
    "sysrq": "Print",
    "space": "space",
    "backspace": "BackSpace",
    "delete": "Delete",
    "del": "Delete",
    "insert": "Insert",
    "ins": "Insert",
    "home": "Home",
    "end": "End",
    "prior": "PageUp",
    "page_up": "PageUp",
    "pageup": "PageUp",
    "next": "PageDown",
    "page_down": "PageDown",
    "pagedown": "PageDown",
    "grave": "grave",
    "minus": "minus",
    "equal": "equal",
    "bracketleft": "bracketleft",
    "bracketright": "bracketright",
    "backslash": "backslash",
    "semicolon": "semicolon",
    "apostrophe": "apostrophe",
    "comma": "comma",
    "period": "period",
    "slash": "slash",
    "capslock": "CapsLock",
    "caps_lock": "CapsLock"
};

function normalizeKeyId(rawKey) {
    if (!rawKey)
        return "";
    if (rawKey.length === 1)
        return rawKey.toUpperCase();
    const lower = rawKey.toLowerCase();
    return KEY_ID_ALIASES[lower] || rawKey;
}

// ---- media key cluster (XF86* binds - not physically part of a TKL
// keyboard, rendered as their own small row) ----
const MEDIA_KEY_IDS = ["XF86AudioMute", "XF86AudioMicMute", "XF86AudioLowerVolume", "XF86AudioRaiseVolume", "XF86AudioPrev", "XF86AudioPlay", "XF86AudioNext", "XF86MonBrightnessDown", "XF86MonBrightnessUp"];

const MEDIA_KEY_LABELS = {
    XF86AudioMute: "Mute",
    XF86AudioMicMute: "Mic",
    XF86AudioLowerVolume: "Vol−",
    XF86AudioRaiseVolume: "Vol+",
    XF86AudioPrev: "⏮",
    XF86AudioPlay: "⏯",
    XF86AudioNext: "⏭",
    XF86MonBrightnessDown: "Bright−",
    XF86MonBrightnessUp: "Bright+"
};

// ---- mouse cluster (button/scroll binds - `{mouse = true}` binds report a
// numeric button code in `key`; scroll binds use the literal keysyms
// "mouse_up"/"mouse_down" like any other key) ----
const MOUSE_SLOTS = [
    {
        id: "mouse:272",
        label: "LMB"
    },
    {
        id: "mouse:273",
        label: "RMB"
    },
    {
        id: "mouse:274",
        label: "MMB"
    },
    {
        id: "mouse_up",
        label: "Scroll ↑"
    },
    {
        id: "mouse_down",
        label: "Scroll ↓"
    }
];

function mouseSlotId(bind) {
    if (bind.key === "mouse_up" || bind.key === "mouse_down")
        return bind.key;
    const m = String(bind.key).match(/(\d+)/);
    return m ? "mouse:" + m[1] : "mouse:other";
}

// Which visual slot (main keyboard / media row / mouse row) a bind belongs to.
function slotIdFor(bind) {
    if (bind.mouse || bind.key === "mouse_up" || bind.key === "mouse_down")
        return mouseSlotId(bind);
    if (MEDIA_KEY_IDS.indexOf(bind.key) >= 0)
        return bind.key;
    return normalizeKeyId(bind.key);
}

function labelForBind(bind) {
    return bind.dispatcher + (bind.arg ? ": " + bind.arg : "");
}

// ---- physical keyboard layout (TKL-ish; unit = 1 key width) ----
function k(id, label, width) {
    return {
        id: id,
        label: label !== undefined ? label : id,
        width: width || 1
    };
}
function gap(width) {
    return {
        id: "",
        label: "",
        width: width,
        spacer: true
    };
}

const KEY_ROWS = [
    [k("Escape", "Esc"), gap(0.5), k("F1"), k("F2"), k("F3"), k("F4"), gap(0.5), k("F5"), k("F6"), k("F7"), k("F8"), gap(0.5), k("F9"), k("F10"), k("F11"), k("F12"), gap(0.5), k("Print", "Prt")],
    [k("grave", "`"), k("1"), k("2"), k("3"), k("4"), k("5"), k("6"), k("7"), k("8"), k("9"), k("0"), k("minus", "-"), k("equal", "="), k("BackSpace", "⌫", 2)],
    [k("Tab", "Tab", 1.5), k("Q"), k("W"), k("E"), k("R"), k("T"), k("Y"), k("U"), k("I"), k("O"), k("P"), k("bracketleft", "["), k("bracketright", "]"), k("backslash", "\\", 1.5)],
    [k("CapsLock", "Caps", 1.75), k("A"), k("S"), k("D"), k("F"), k("G"), k("H"), k("J"), k("K"), k("L"), k("semicolon", ";"), k("apostrophe", "'"), k("Return", "Enter", 2.25)],
    [k("ShiftL", "Shift", 2.25), k("Z"), k("X"), k("C"), k("V"), k("B"), k("N"), k("M"), k("comma", ","), k("period", "."), k("slash", "/"), k("ShiftR", "Shift", 2.75)],
    [k("CtrlL", "Ctrl", 1.25), k("SuperL", "Super", 1.25), k("AltL", "Alt", 1.25), k("space", "", 6.25), k("AltR", "Alt", 1.25), k("SuperR", "Super", 1.25), k("Menu", "Menu", 1.25), k("CtrlR", "Ctrl", 1.25)]
];

// Rendered as a separate small block to the right of rows 4-5.
const ARROW_CLUSTER = [
    [gap(1), k("Up", "↑")],
    [k("Left", "←"), k("Down", "↓"), k("Right", "→")]
];

// Modifier keys never appear as a bind's primary `key` in this config (they
// only ever contribute to modmask) - excluded from "free key" counting since
// they'd always read as free regardless of what's actually bound.
const STRUCTURAL_IDS = ["ShiftL", "ShiftR", "CtrlL", "CtrlR", "AltL", "AltR", "SuperL", "SuperR", "Menu", "CapsLock"];

const ALL_KEY_IDS = (function () {
    const ids = [];
    for (const row of KEY_ROWS)
        for (const key of row)
            if (!key.spacer && key.id)
                ids.push(key.id);
    for (const row of ARROW_CLUSTER)
        for (const key of row)
            if (!key.spacer && key.id)
                ids.push(key.id);
    return ids;
})();

const COUNTABLE_KEY_IDS = ALL_KEY_IDS.filter(id => STRUCTURAL_IDS.indexOf(id) < 0);

// id -> display label, used by the inspector panel for any slot (main
// keyboard, media, or mouse).
const KEY_ID_TO_LABEL = (function () {
    const map = {};
    for (const row of KEY_ROWS)
        for (const key of row)
            if (!key.spacer)
                map[key.id] = key.label;
    for (const row of ARROW_CLUSTER)
        for (const key of row)
            if (!key.spacer)
                map[key.id] = key.label;
    for (const id in MEDIA_KEY_LABELS)
        map[id] = MEDIA_KEY_LABELS[id];
    for (const slot of MOUSE_SLOTS)
        map[slot.id] = slot.label;
    return map;
})();

function displayKeyLabel(bind) {
    return KEY_ID_TO_LABEL[bind.slotId] || bind.key || bind.slotId || "?";
}

// ---- best-effort mapping from a parsed bind back to its source line in
// keybinds.lua (for "open in editor" - see Editor.qml). This is a text
// heuristic over `hl.bind(...)` call lines, not a real Lua parse: it works
// for every bind in this config that's written as one literal call per key
// (which is nearly all of them), but a bind built from a loop variable
// (the mod+0-9 workspace-switch loop) has no single line to point at, so
// those resolve to the loop's own line instead of a specific key's line.
// Submap tracking assumes `hl.define_submap("name", function() ... end)` is
// the only multi-line block that closes on a bare `end)` while a submap is
// open - true for this file today, but fragile if that ever changes.
const MOD_TOKEN_TO_NAME = {
    SHIFT: "Shift",
    CTRL: "Ctrl",
    ALT: "Alt"
};

function _lineModsAndKey(line) {
    const m = line.match(/"([^"]*)"/);
    if (!m)
        return null;
    const hasMod = /\bmod\b/.test(line);
    const parts = m[1].split("+").map(s => s.trim()).filter(s => s.length > 0);

    let key = "";
    const mods = [];
    for (const part of parts) {
        const upper = part.toUpperCase();
        if (MOD_TOKEN_TO_NAME[upper])
            mods.push(MOD_TOKEN_TO_NAME[upper]);
        else
            key = part;
    }
    if (hasMod)
        mods.unshift("Super");

    return {
        mods: mods,
        key: key,
        // a bare identifier immediately concatenated in (`.. key,` / `.. i)`)
        // means the key here is a loop variable, not a literal
        dynamic: key === "" && /\.\.\s*\w+\s*[,)]/.test(line)
    };
}

function _modsEqual(a, b) {
    if (a.length !== b.length)
        return false;
    const sa = a.slice().sort();
    const sb = b.slice().sort();
    return sa.every((v, i) => v === sb[i]);
}

function findSourceLine(sourceText, bind) {
    const lines = sourceText.split("\n");
    let submap = "";
    let bestDynamicLine = -1;

    for (let i = 0; i < lines.length; i++) {
        const line = lines[i];
        const trimmed = line.trim();

        // Skip commented-out lines entirely, both to avoid a `-- hl.bind(...)`
        // example matching before the real one below it, and because a
        // commented-out `-- hl.define_submap(...)` would otherwise be read
        // as a real submap boundary and poison tracking for the rest of the
        // file (its matching `-- end)` is also commented out, so it would
        // never close again).
        if (trimmed.startsWith("--"))
            continue;

        const submapOpen = trimmed.match(/hl\.define_submap\(\s*"([^"]+)"/);
        if (submapOpen) {
            submap = submapOpen[1];
            continue;
        }
        if (trimmed === "end)" && submap !== "") {
            submap = "";
            continue;
        }

        if (!line.includes("hl.bind(") || submap !== bind.submap)
            continue;

        const parsed = _lineModsAndKey(line);
        if (!parsed || !_modsEqual(parsed.mods, bind.mods))
            continue;

        if (parsed.key) {
            const lowerKey = parsed.key.toLowerCase();
            if (normalizeKeyId(parsed.key) === normalizeKeyId(bind.key) || lowerKey === String(bind.slotId).toLowerCase() || lowerKey === String(bind.key).toLowerCase())
                return i + 1;
        } else if (parsed.dynamic && bestDynamicLine < 0) {
            bestDynamicLine = i + 1;
        }
    }

    return bestDynamicLine > 0 ? bestDynamicLine : null;
}
