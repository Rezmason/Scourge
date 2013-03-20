package net.rezmason.scourge.textview;

class Almanac {
    public inline static var NUM_GEOM_FLOATS_PER_VERTEX:Int = 3 + 2 + 1; // X,Y,Z H,V S
    public inline static var NUM_COLOR_FLOATS_PER_VERTEX:Int = 3 + 2 + 1; // R,G,B U,V I
    public inline static var NUM_ID_FLOATS_PER_VERTEX:Int = 3; // ID_0, ID_1, ID_2

    public inline static var NUM_VERTICES_PER_QUAD:Int = 4;
    public inline static var NUM_GEOM_FLOATS_PER_QUAD:Int = NUM_GEOM_FLOATS_PER_VERTEX * NUM_VERTICES_PER_QUAD;
    public inline static var NUM_COLOR_FLOATS_PER_QUAD:Int = NUM_COLOR_FLOATS_PER_VERTEX * NUM_VERTICES_PER_QUAD;
    public inline static var NUM_ID_FLOATS_PER_QUAD:Int = NUM_ID_FLOATS_PER_VERTEX * NUM_VERTICES_PER_QUAD;

    public inline static var NUM_TRIANGLES_PER_QUAD:Int = 2;
    public inline static var NUM_INDICES_PER_TRIANGLE:Int = 3;
    public inline static var NUM_INDICES_PER_QUAD:Int = NUM_TRIANGLES_PER_QUAD * NUM_INDICES_PER_TRIANGLE;
    public inline static var BUFFER_SIZE:Int = 0xFFFF;
    public inline static var CHAR_QUAD_CHUNK:Int = Std.int(BUFFER_SIZE / NUM_VERTICES_PER_QUAD);
}
