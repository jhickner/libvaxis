const std = @import("std");
const testing = std.testing;
const ziglyph = @import("ziglyph");

const Key = @This();

pub const Modifiers = packed struct(u8) {
    shift: bool = false,
    alt: bool = false,
    ctrl: bool = false,
    super: bool = false,
    hyper: bool = false,
    meta: bool = false,
    caps_lock: bool = false,
    num_lock: bool = false,
};

/// the unicode codepoint of the key event.
codepoint: u21,

/// the text generated from the key event. The underlying slice has a limited
/// lifetime. Vaxis maintains an internal ring buffer to temporarily store text.
/// If the application needs these values longer than the lifetime of the event
/// it must copy the data.
text: ?[]const u8 = null,

/// the shifted codepoint of this key event. This will only be present if the
/// Shift modifier was used to generate the event
shifted_codepoint: ?u21 = null,

/// the key that would have been pressed on a standard keyboard layout. This is
/// useful for shortcut matching
base_layout_codepoint: ?u21 = null,

mods: Modifiers = .{},

// matches follows a loose matching algorithm for key matches.
// 1. If the codepoint and modifiers are exact matches
// 2. If the utf8 encoding of the codepoint matches the text
// 3. If there is a shifted codepoint and it matches after removing the shift
//    modifier from self
pub fn matches(self: Key, cp: u21, mods: Modifiers) bool {
    // rule 1
    if (self.matchExact(cp, mods)) return true;

    // rule 2
    if (self.matchText(cp, mods)) return true;

    // rule 3
    if (self.matchShiftedCodepoint(cp, mods)) return true;

    // rule 4
    if (self.matchShiftedCodepoint(cp, mods)) return true;

    return false;
}

// matches base layout codes, useful for shortcut matching when an alternate key
// layout is used
pub fn matchShortcut(self: Key, cp: u21, mods: Modifiers) bool {
    if (self.base_layout_codepoint == null) return false;
    return cp == self.base_layout_codepoint.? and std.meta.eql(self.mods, mods);
}

// matches keys that aren't upper case versions when shifted. For example, shift
// + semicolon produces a colon. The key can be matched against shift +
// semicolon or just colon...or shift + ctrl + ; or just ctrl + :
pub fn matchShiftedCodepoint(self: Key, cp: u21, mods: Modifiers) bool {
    if (self.shifted_codepoint == null) return false;
    if (!self.mods.shift) return false;
    var self_mods = self.mods;
    self_mods.shift = false;
    return cp == self.shifted_codepoint.? and std.meta.eql(self_mods, mods);
}

// matches when the utf8 encoding of the codepoint and relevant mods matches the
// text of the key. This function will consume Shift and Caps Lock when matching
pub fn matchText(self: Key, cp: u21, mods: Modifiers) bool {
    // return early if we have no text
    if (self.text == null) return false;

    var self_mods = self.mods;
    var arg_mods = mods;
    var code = cp;
    // if the passed codepoint is upper, we consume all shift and caps mods for
    // checking
    if (ziglyph.isUpper(cp)) {
        // consume mods
        self_mods.shift = false;
        self_mods.caps_lock = false;
        arg_mods.shift = false;
        arg_mods.caps_lock = false;
    } else if (mods.shift or mods.caps_lock) {
        // uppercase the cp and consume all mods
        code = ziglyph.toUpper(cp);
        self_mods.shift = false;
        self_mods.caps_lock = false;
        arg_mods.shift = false;
        arg_mods.caps_lock = false;
    }

    var buf: [4]u8 = undefined;
    const n = std.unicode.utf8Encode(cp, buf[0..]) catch return false;
    return std.mem.eql(u8, self.text.?, buf[0..n]) and std.meta.eql(self_mods, arg_mods);
}

// The key must exactly match the codepoint and modifiers
pub fn matchExact(self: Key, cp: u21, mods: Modifiers) bool {
    return self.codepoint == cp and std.meta.eql(self.mods, mods);
}

// a few special keys that we encode as their actual ascii value
pub const enter: u21 = 0x0D;
pub const tab: u21 = 0x09;
pub const escape: u21 = 0x1B;
pub const space: u21 = 0x20;
pub const backspace: u21 = 0x7F;

// multicodepoint is a key which generated text but cannot be expressed as a
// single codepoint. The value is the maximum unicode codepoint + 1
pub const multicodepoint: u21 = 1_114_112 + 1;

// kitty encodes these keys directly in the private use area. We reuse those
// mappings
pub const insert: u21 = 57348;
pub const delete: u21 = 57349;
pub const left: u21 = 57350;
pub const right: u21 = 57351;
pub const up: u21 = 57352;
pub const down: u21 = 57353;
pub const page_up: u21 = 57354;
pub const page_down: u21 = 57355;
pub const home: u21 = 57356;
pub const end: u21 = 57357;
pub const caps_lock: u21 = 57358;
pub const scroll_lock: u21 = 57359;
pub const num_lock: u21 = 57360;
pub const print_screen: u21 = 57361;
pub const pause: u21 = 57362;
pub const menu: u21 = 57363;
pub const f1: u21 = 57364;
pub const f2: u21 = 57365;
pub const f3: u21 = 57366;
pub const f4: u21 = 57367;
pub const f5: u21 = 57368;
pub const f6: u21 = 57369;
pub const f7: u21 = 57370;
pub const f8: u21 = 57371;
pub const f9: u21 = 57372;
pub const f10: u21 = 57373;
pub const f11: u21 = 57374;
pub const f12: u21 = 57375;
pub const f13: u21 = 57376;
pub const f14: u21 = 57377;
pub const f15: u21 = 57378;
pub const @"f16": u21 = 57379;
pub const f17: u21 = 57380;
pub const f18: u21 = 57381;
pub const f19: u21 = 57382;
pub const f20: u21 = 57383;
pub const f21: u21 = 57384;
pub const f22: u21 = 57385;
pub const f23: u21 = 57386;
pub const f24: u21 = 57387;
pub const f25: u21 = 57388;
pub const f26: u21 = 57389;
pub const f27: u21 = 57390;
pub const f28: u21 = 57391;
pub const f29: u21 = 57392;
pub const f30: u21 = 57393;
pub const f31: u21 = 57394;
pub const @"f32": u21 = 57395;
pub const f33: u21 = 57396;
pub const f34: u21 = 57397;
pub const f35: u21 = 57398;
pub const kp_0: u21 = 57399;
pub const kp_1: u21 = 57400;
pub const kp_2: u21 = 57401;
pub const kp_3: u21 = 57402;
pub const kp_4: u21 = 57403;
pub const kp_5: u21 = 57404;
pub const kp_6: u21 = 57405;
pub const kp_7: u21 = 57406;
pub const kp_8: u21 = 57407;
pub const kp_9: u21 = 57408;
pub const kp_begin: u21 = 57427;
// TODO: Finish the kitty keys

test "matches 'a'" {
    const key: Key = .{
        .codepoint = 'a',
    };
    try testing.expect(key.matches('a', .{}));
}

test "matches 'shift+a'" {
    const key: Key = .{
        .codepoint = 'a',
        .mods = .{ .shift = true },
        .text = "A",
    };
    try testing.expect(key.matches('a', .{ .shift = true }));
    try testing.expect(key.matches('A', .{}));
    try testing.expect(!key.matches('A', .{ .ctrl = true }));
}

test "matches 'shift+tab'" {
    const key: Key = .{
        .codepoint = Key.tab,
        .mods = .{ .shift = true },
    };
    try testing.expect(key.matches(Key.tab, .{ .shift = true }));
    try testing.expect(!key.matches(Key.tab, .{}));
}

test "matches 'shift+;'" {
    const key: Key = .{
        .codepoint = ';',
        .shifted_codepoint = ':',
        .mods = .{ .shift = true },
        .text = ":",
    };
    try testing.expect(key.matches(';', .{ .shift = true }));
    try testing.expect(key.matches(':', .{}));

    const colon: Key = .{
        .codepoint = ':',
        .mods = .{},
    };
    try testing.expect(colon.matches(':', .{}));
}
