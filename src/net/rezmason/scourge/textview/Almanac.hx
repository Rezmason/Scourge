package net.rezmason.scourge.textview;

class Almanac {
    public inline static var NUM_VERTICES_PER_GLYPH:Int = 4;
    public inline static var NUM_TRIANGLES_PER_GLYPH:Int = 2;
    public inline static var NUM_INDICES_PER_TRIANGLE:Int = 3;
    public inline static var NUM_INDICES_PER_GLYPH:Int = NUM_TRIANGLES_PER_GLYPH * NUM_INDICES_PER_TRIANGLE;

    public inline static var NUM_SHAPE_FLOATS_PER_VERTEX:Int = 3 + 2 + 1 + 1; // X,Y,Z H,V S P
    public inline static var NUM_COLOR_FLOATS_PER_VERTEX:Int = 3 + 2 + 1; // R,G,B U,V I
    public inline static var NUM_PAINT_FLOATS_PER_VERTEX:Int = 3; // PAINT_0, PAINT_1, PAINT_2

    public inline static var NUM_SHAPE_FLOATS_PER_GLYPH:Int = NUM_SHAPE_FLOATS_PER_VERTEX * NUM_VERTICES_PER_GLYPH;
    public inline static var NUM_COLOR_FLOATS_PER_GLYPH:Int = NUM_COLOR_FLOATS_PER_VERTEX * NUM_VERTICES_PER_GLYPH;
    public inline static var NUM_PAINT_FLOATS_PER_GLYPH:Int = NUM_PAINT_FLOATS_PER_VERTEX * NUM_VERTICES_PER_GLYPH;

    public inline static var BUFFER_SIZE:Int = 0xFFFF;
    public inline static var BUFFER_CHUNK:Int = Std.int(BUFFER_SIZE / NUM_VERTICES_PER_GLYPH);
}
