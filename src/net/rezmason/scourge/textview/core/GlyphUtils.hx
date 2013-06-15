package net.rezmason.scourge.textview.core;

import flash.Vector;

import net.rezmason.utils.FatChar;
import net.rezmason.utils.FlatFont;

typedef G = Glyph;

class GlyphUtils {

    static var blank:Int = ' '.charCodeAt(0);

    inline static var spv:Int = Almanac.SHAPE_FLOATS_PER_VERTEX;
    inline static var cpv:Int = Almanac.COLOR_FLOATS_PER_VERTEX;
    inline static var ppv:Int = Almanac.PAINT_FLOATS_PER_VERTEX;

    // The whole shebang

    public inline static function prime(gl:G) {
        for (ike in 0...spv * 4) gl.shape[ike] = 0;
        for (ike in 0...cpv * 4) gl.color[ike] = 0;
        for (ike in 0...ppv * 4) gl.paint[ike] = 0;
        makeCorners(gl);
    }

    // Color

    public inline static function get_r(gl:G) { return gl.color[0]; }
    public inline static function set_r(gl:G, v) { mark(gl); return pop4(gl.color, 0, cpv, v); }

    public inline static function get_g(gl:G) { return gl.color[1]; }
    public inline static function set_g(gl:G, v) { mark(gl); return pop4(gl.color, 1, cpv, v); }

    public inline static function get_b(gl:G) { return gl.color[2]; }
    public inline static function set_b(gl:G, v) { mark(gl); return pop4(gl.color, 2, cpv, v); }

    public inline static function get_i(gl:G) { return gl.color[5]; }
    public inline static function set_i(gl:G, v) { mark(gl); return pop4(gl.color, 5, cpv, v); }

    public inline static function set_color(gl:G, r, g, b) {
        set_r(gl, r);
        set_g(gl, g);
        set_b(gl, b);
    }

    // Shape

    public inline static function get_x(gl:G) { return gl.shape[0]; }
    public inline static function set_x(gl:G, v) { mark(gl); return pop4(gl.shape, 0, spv, v); }
    public inline static function get_y(gl:G) { return gl.shape[1]; }
    public inline static function set_y(gl:G, v) { mark(gl); return pop4(gl.shape, 1, spv, v); }
    public inline static function get_z(gl:G) { return gl.shape[2]; }
    public inline static function set_z(gl:G, v) { mark(gl); return pop4(gl.shape, 2, spv, v); }

    public inline static function get_s(gl:G) { return gl.shape[5]; }
    public inline static function set_s(gl:G, v) { mark(gl); return pop4(gl.shape, 5, spv, v); }

    public inline static function get_p(gl:G) { return gl.shape[6]; }
    public inline static function set_p(gl:G, v) { mark(gl); return pop4(gl.shape, 6, spv, v); }

    public inline static function set_shape(gl:G, x, y, z, s, p) {
        set_pos(gl, x, y, z);
        set_s(gl, s);
        set_p(gl, p);
    }

    public inline static function set_pos(gl:G, x, y, z) {
        set_x(gl, x);
        set_y(gl, y);
        set_z(gl, z);
    }

    public inline static function makeCorners(gl:G):Void {
        mark(gl);

        gl.shape[3 + 0 * spv] = 0; gl.shape[4 + 0 * spv] = 0;
        gl.shape[3 + 1 * spv] = 0; gl.shape[4 + 1 * spv] = 1;
        gl.shape[3 + 2 * spv] = 1; gl.shape[4 + 2 * spv] = 1;
        gl.shape[3 + 3 * spv] = 1; gl.shape[4 + 3 * spv] = 0;
    }

    // Character

    public inline static function get_char(gl:G) { return gl.charCode; }

    public inline static function set_char(gl:G, code, font:FlatFont) {
        if (get_char(gl) != code) {
            mark(gl);
            var charUV = font.getCharCodeUVs(code);
            gl.color[3 + 0 * cpv] = charUV[3].u; gl.color[4 + 0 * cpv] = charUV[3].v;
            gl.color[3 + 1 * cpv] = charUV[0].u; gl.color[4 + 1 * cpv] = charUV[0].v;
            gl.color[3 + 2 * cpv] = charUV[1].u; gl.color[4 + 2 * cpv] = charUV[1].v;
            gl.color[3 + 3 * cpv] = charUV[2].u; gl.color[4 + 3 * cpv] = charUV[2].v;
            gl.charCode = code;
        }
        return code;
    }

    // Paint

    public inline static function get_paint(gl:G) { return gl._paint; }

    public inline static function set_paint(gl:G, val:Int) {
        mark(gl);

        if (get_paint(gl) != val) {

            var paintR = ((val >> 16) & 0xFF) / 0xFF;
            var paintG = ((val >>  8) & 0xFF) / 0xFF;
            var paintB = ((val >>  0) & 0xFF) / 0xFF;

            pop4(gl.paint, 0, ppv, paintR);
            pop4(gl.paint, 1, ppv, paintG);
            pop4(gl.paint, 2, ppv, paintB);

            gl._paint = val;
        }

        return gl._paint;
    }

    private inline static function pop4(vec:Vector<Float>, offset:Int, step:Int, val:Float):Float {
        if (vec[offset + 0 * step] != val) {
            vec[offset + 0 * step] = val;
            vec[offset + 1 * step] = val;
            vec[offset + 2 * step] = val;
            vec[offset + 3 * step] = val;
        }
        return val;
    }

    private inline static function mark(gl:G) { gl.dirty = true; }
}
