package net.rezmason.scourge;

import net.rezmason.math.Vec3;

class ScourgeColorPalette {
    public static var TEAM_COLORS:Array<Vec3> = [0xFF0090, 0xFFC800, 0x30FF00, 0x00C0FF, 0xFF6000, 0xC000FF, 0x0030FF, 0x606060, ].map(Vec3.fromHex);
    public static var BOARD_COLOR:Vec3 = Vec3.fromHex(0x202020);
    public static var WALL_COLOR:Vec3 = Vec3.fromHex(0x808080);
    public static var UI_COLOR:Vec3 = Vec3.fromHex(0xFFFFFF);
    public static var BLACK:Vec3 = new Vec3(0, 0, 0);
    public static var WHITE:Vec3 = new Vec3(1, 1, 1);
}
