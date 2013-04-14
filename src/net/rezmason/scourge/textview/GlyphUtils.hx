package net.rezmason.scourge.textview;

import net.rezmason.utils.FatChar;
import net.rezmason.utils.FlatFont;

class GlyphUtils {

    /*
    public inline static var SHAPE_FLOATS_PER_VERTEX:Int = 3 + 2 + 1 + 1; // X,Y,Z H,V S P
    public inline static var COLOR_FLOATS_PER_VERTEX:Int = 3 + 2 + 1; // R,G,B U,V I
    public inline static var PAINT_FLOATS_PER_VERTEX:Int = 3; // PAINT_0, PAINT_1, PAINT_2; }
    */

    public inline static function set_shape(glyph:Glyph, x:Float, y:Float, z:Float, s:Float, p:Float):Void {
        glyph.dirty = true;
        set_x(glyph, x);
        set_y(glyph, y);
        set_z(glyph, z);
        set_s(glyph, s);
        set_p(glyph, p);
    }

    public inline static function set_color(glyph:Glyph, r:Float, g:Float, b:Float, i:Float):Void {
        glyph.dirty = true;
        set_r(glyph, r);
        set_g(glyph, g);
        set_b(glyph, b);
        set_i(glyph, i);
    }

    public inline static function makeCorners(glyph:Glyph):Void {
        glyph.dirty = true;
        var n:Int = Almanac.SHAPE_FLOATS_PER_VERTEX;

        glyph.shape[3 + 0 * n] = 0; glyph.shape[4 + 0 * n] = 0;
        glyph.shape[3 + 1 * n] = 0; glyph.shape[4 + 1 * n] = 1;
        glyph.shape[3 + 2 * n] = 1; glyph.shape[4 + 2 * n] = 1;
        glyph.shape[3 + 3 * n] = 1; glyph.shape[4 + 3 * n] = 0;
    }

    public inline static function get_char(glyph:Glyph):Int {
        return glyph.charCode;
    }

    public inline static function set_char(glyph:Glyph, code:Int, font:FlatFont):Int {
        glyph.dirty = true;

        var n:Int = Almanac.COLOR_FLOATS_PER_VERTEX;

        var charUV = font.getCharCodeUVs(code);
        glyph.color[3 + 0 * n] = charUV[3].u; glyph.color[4 + 0 * n] = charUV[3].v;
        glyph.color[3 + 1 * n] = charUV[0].u; glyph.color[4 + 1 * n] = charUV[0].v;
        glyph.color[3 + 2 * n] = charUV[1].u; glyph.color[4 + 2 * n] = charUV[1].v;
        glyph.color[3 + 3 * n] = charUV[2].u; glyph.color[4 + 3 * n] = charUV[2].v;

        glyph.charCode = code;
        return code;
    }

    public inline static function get_r(glyph:Glyph):Float {
        return glyph.color[0];
    }

    public inline static function set_r(glyph:Glyph, val:Float):Float {
        glyph.dirty = true;
        return populate4(glyph.color, 0, Almanac.COLOR_FLOATS_PER_VERTEX, val);
    }

    public inline static function get_g(glyph:Glyph):Float {
        return glyph.color[1];
    }

    public inline static function set_g(glyph:Glyph, val:Float):Float {
        glyph.dirty = true;
        return populate4(glyph.color, 1, Almanac.COLOR_FLOATS_PER_VERTEX, val);
    }

    public inline static function get_b(glyph:Glyph):Float {
        return glyph.color[2];
    }

    public inline static function set_b(glyph:Glyph, val:Float):Float {
        glyph.dirty = true;
        return populate4(glyph.color, 2, Almanac.COLOR_FLOATS_PER_VERTEX, val);
    }

    public inline static function get_i(glyph:Glyph):Float {
        return glyph.color[5];
    }

    public inline static function set_i(glyph:Glyph, val:Float):Float {
        glyph.dirty = true;
        return populate4(glyph.color, 5, Almanac.COLOR_FLOATS_PER_VERTEX, val);
    }

    public inline static function get_x(glyph:Glyph):Float {
        return glyph.shape[0];
    }

    public inline static function set_x(glyph:Glyph, val:Float):Float {
        glyph.dirty = true;
        return populate4(glyph.shape, 0, Almanac.SHAPE_FLOATS_PER_VERTEX, val);
    }

    public inline static function get_y(glyph:Glyph):Float {
        return glyph.shape[1];
    }

    public inline static function set_y(glyph:Glyph, val:Float):Float {
        glyph.dirty = true;
        return populate4(glyph.shape, 1, Almanac.SHAPE_FLOATS_PER_VERTEX, val);
    }

    public inline static function get_z(glyph:Glyph):Float {
        return glyph.shape[2];
    }

    public inline static function set_z(glyph:Glyph, val:Float):Float {
        glyph.dirty = true;
        return populate4(glyph.shape, 2, Almanac.SHAPE_FLOATS_PER_VERTEX, val);
    }

    public inline static function get_s(glyph:Glyph):Float {
        return glyph.shape[5];
    }

    public inline static function set_s(glyph:Glyph, val:Float):Float {
        glyph.dirty = true;
        return populate4(glyph.shape, 5, Almanac.SHAPE_FLOATS_PER_VERTEX, val);
    }

    public inline static function get_p(glyph:Glyph):Float {
        return glyph.shape[6];
    }

    public inline static function set_p(glyph:Glyph, val:Float):Float {
        glyph.dirty = true;
        return populate4(glyph.shape, 6, Almanac.SHAPE_FLOATS_PER_VERTEX, val);
    }

    public inline static function get_paint(glyph:Glyph, val:Int):Int {
        return glyph._paint;
    }

    public inline static function set_paint(glyph:Glyph, val:Int):Int {
        glyph.dirty = true;

        val = val + 1;

        var paintR:Float = ((val >> 16) & 0xFF) / 0xFF;
        var paintG:Float = ((val >>  8) & 0xFF) / 0xFF;
        var paintB:Float = ((val >>  0) & 0xFF) / 0xFF;

        populate4(glyph.paint, 0, Almanac.PAINT_FLOATS_PER_VERTEX, paintR);
        populate4(glyph.paint, 1, Almanac.PAINT_FLOATS_PER_VERTEX, paintG);
        populate4(glyph.paint, 2, Almanac.PAINT_FLOATS_PER_VERTEX, paintB);

        glyph._paint = val;
        return glyph._paint;
    }

    private inline static function populate4<T>(arr:Array<T>, offset:Int, step:Int, val:T):T {
        arr[offset + 0 * step] = val;
        arr[offset + 1 * step] = val;
        arr[offset + 2 * step] = val;
        arr[offset + 3 * step] = val;
        return val;
    }
}
