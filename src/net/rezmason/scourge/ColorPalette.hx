package net.rezmason.scourge;

import net.rezmason.math.Vec4;

class ColorPalette {
    public static var TEAM_COLORS:Array<Vec4> = [0xFF0090, 0xFFC800, 0x30FF00, 0x00C0FF, 0xFF6000, 0xC000FF, 0x0030FF, 0x606060, ].map(Vec4.fromHex);
    public static var BOARD_COLOR:Vec4 = Vec4.fromHex(0x202020);
    public static var WALL_COLOR:Vec4 = Vec4.fromHex(0x808080);
    public static var UI_COLOR:Vec4 = Vec4.fromHex(0xFFFFFF);
    public static var BLACK:Vec4 = new Vec4(0, 0, 0);
    public static var WHITE:Vec4 = new Vec4(1, 1, 1);
}
