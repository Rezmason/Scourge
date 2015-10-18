package net.rezmason.scourge.textview.core;

class Almanac {

    public inline static var R_OFFSET:Int = 0;
    public inline static var G_OFFSET:Int = 1;
    public inline static var B_OFFSET:Int = 2;
    public inline static var U_OFFSET:Int = 3;
    public inline static var V_OFFSET:Int = 4;
    public inline static var I_OFFSET:Int = 5;
    public inline static var F_OFFSET:Int = 6;
    public inline static var A_OFFSET:Int = 7;

    public inline static var X_OFFSET:Int = 0;
    public inline static var Y_OFFSET:Int = 1;
    public inline static var Z_OFFSET:Int = 2;
    public inline static var CORNER_H_OFFSET:Int = 3;
    public inline static var CORNER_V_OFFSET:Int = 4;
    public inline static var H_OFFSET:Int = 5;
    public inline static var S_OFFSET:Int = 6;
    public inline static var P_OFFSET:Int = 7;

    public inline static var PAINT_R_OFFSET:Int = 0;
    public inline static var PAINT_G_OFFSET:Int = 1;
    public inline static var PAINT_H_OFFSET:Int = 2;
    public inline static var PAINT_S_OFFSET:Int = 3;

    public inline static var VERTICES_PER_GLYPH:Int = 4;
    public inline static var TRIANGLES_PER_GLYPH:Int = 2;
    public inline static var INDICES_PER_TRIANGLE:Int = 3;
    public inline static var INDICES_PER_GLYPH:Int = TRIANGLES_PER_GLYPH * INDICES_PER_TRIANGLE;

    public inline static var COLOR_FLOATS_PER_VERTEX:Int = 3 + 2 + 3; // R,G,B U,V I,F,A
    public inline static var SHAPE_FLOATS_PER_VERTEX:Int = 3 + 2 + 3; // X,Y,Z CH,CV H,S,P
    public inline static var PAINT_FLOATS_PER_VERTEX:Int = 2 + 2; // PAINT_R,PAINT_G PAINT_H,PAINT_S

    public inline static var SHAPE_FLOATS_PER_GLYPH:Int = SHAPE_FLOATS_PER_VERTEX * VERTICES_PER_GLYPH;
    public inline static var COLOR_FLOATS_PER_GLYPH:Int = COLOR_FLOATS_PER_VERTEX * VERTICES_PER_GLYPH;
    public inline static var PAINT_FLOATS_PER_GLYPH:Int = PAINT_FLOATS_PER_VERTEX * VERTICES_PER_GLYPH;

    public inline static var BUFFER_SIZE:Int = 0xFFFF;
    public inline static var BUFFER_CHUNK:Int = Std.int(BUFFER_SIZE / VERTICES_PER_GLYPH);

    public static var VERT_ORDER:Array<UInt> = [0, 1, 2, 0, 2, 3,];
}
