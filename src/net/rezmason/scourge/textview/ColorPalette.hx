package net.rezmason.scourge.textview;

class ColorPalette {
    public static var TEAM_COLORS:Array<Color> = [0xFF0090, 0xFFC800, 0x30FF00, 0x00C0FF, 0xFF6000, 0xC000FF, 0x0030FF, 0x606060, ].map(Color.fromHex);
    public static var BOARD_COLOR:Color = Color.fromHex(0x202020);
    public static var WALL_COLOR:Color = Color.fromHex(0x808080);
    public static var UI_COLOR:Color = Color.fromHex(0xFFFFFF);
    public static var BLACK:Color = new Color(0, 0, 0);
    public static var WHITE:Color = new Color(1, 1, 1);
}
