package net.rezmason.scourge.textview.core;

import net.rezmason.gl.Types;

import net.rezmason.utils.FatChar;
import net.rezmason.utils.FlatFont;

typedef G = Glyph;

class GlyphUtils {

    inline static var R_OFFSET:Int = 0;
    inline static var G_OFFSET:Int = 1;
    inline static var B_OFFSET:Int = 2;
    inline static var U_OFFSET:Int = 3;
    inline static var V_OFFSET:Int = 4;
    inline static var I_OFFSET:Int = 5;

    inline static var X_OFFSET:Int = 0;
    inline static var Y_OFFSET:Int = 1;
    inline static var Z_OFFSET:Int = 2;
    inline static var CH_OFFSET:Int = 3;
    inline static var CV_OFFSET:Int = 4;
    inline static var S_OFFSET:Int = 5;
    inline static var P_OFFSET:Int = 6;

    inline static var PR_OFFSET:Int = 0;
    inline static var PG_OFFSET:Int = 1;
    inline static var PB_OFFSET:Int = 2;

    static var blank:Int = ' '.charCodeAt(0);

    inline static var spv:Int = Almanac.SHAPE_FLOATS_PER_VERTEX;
    inline static var cpv:Int = Almanac.COLOR_FLOATS_PER_VERTEX;
    inline static var ppv:Int = Almanac.PAINT_FLOATS_PER_VERTEX;

    inline static var spg:Int = Almanac.SHAPE_FLOATS_PER_GLYPH;
    inline static var cpg:Int = Almanac.COLOR_FLOATS_PER_GLYPH;
    inline static var ppg:Int = Almanac.PAINT_FLOATS_PER_GLYPH;

    // Color

    public inline static function get_r(gl:G) { return gl.color[gl.id * cpg + R_OFFSET]; }
    public inline static function set_r(gl:G, v) { return pop4(gl.color, gl.id * cpg, R_OFFSET, cpv, v); }

    public inline static function get_g(gl:G) { return gl.color[gl.id * cpg + G_OFFSET]; }
    public inline static function set_g(gl:G, v) { return pop4(gl.color, gl.id * cpg, G_OFFSET, cpv, v); }

    public inline static function get_b(gl:G) { return gl.color[gl.id * cpg + B_OFFSET]; }
    public inline static function set_b(gl:G, v) { return pop4(gl.color, gl.id * cpg, B_OFFSET, cpv, v); }

    public inline static function get_i(gl:G) { return gl.color[gl.id * cpg + I_OFFSET]; }
    public inline static function set_i(gl:G, v) { return pop4(gl.color, gl.id * cpg, I_OFFSET, cpv, v); }

    public inline static function set_color(gl:G, r, g, b) {
        set_r(gl, r);
        set_g(gl, g);
        set_b(gl, b);
    }

    // Shape

    public inline static function get_x(gl:G) { return gl.shape[gl.id * spg + X_OFFSET]; }
    public inline static function set_x(gl:G, v) { return pop4(gl.shape, gl.id * spg, X_OFFSET, spv, v); }
    public inline static function get_y(gl:G) { return gl.shape[gl.id * spg + Y_OFFSET]; }
    public inline static function set_y(gl:G, v) { return pop4(gl.shape, gl.id * spg, Y_OFFSET, spv, v); }
    public inline static function get_z(gl:G) { return gl.shape[gl.id * spg + Z_OFFSET]; }
    public inline static function set_z(gl:G, v) { return pop4(gl.shape, gl.id * spg, Z_OFFSET, spv, v); }

    public inline static function get_s(gl:G) { return gl.shape[gl.id * spg + S_OFFSET]; }
    public inline static function set_s(gl:G, v) { return pop4(gl.shape, gl.id * spg, S_OFFSET, spv, v); }

    public inline static function get_p(gl:G) { return gl.shape[gl.id * spg + P_OFFSET]; }
    public inline static function set_p(gl:G, v) { return pop4(gl.shape, gl.id * spg, P_OFFSET, spv, v); }

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
        var glyphOffset:Int = gl.id * spg;
        pop1(gl.shape, glyphOffset, CH_OFFSET + 0 * spv, 0);
        pop1(gl.shape, glyphOffset, CH_OFFSET + 1 * spv, 0);
        pop1(gl.shape, glyphOffset, CH_OFFSET + 2 * spv, 1);
        pop1(gl.shape, glyphOffset, CH_OFFSET + 3 * spv, 1);

        pop1(gl.shape, glyphOffset, CV_OFFSET + 0 * spv, 0);
        pop1(gl.shape, glyphOffset, CV_OFFSET + 1 * spv, 1);
        pop1(gl.shape, glyphOffset, CV_OFFSET + 2 * spv, 1);
        pop1(gl.shape, glyphOffset, CV_OFFSET + 3 * spv, 0);
    }

    // Character

    public inline static function get_char(gl:G) { return gl.charCode; }

    public inline static function set_char(gl:G, code, font:FlatFont) {
        if (get_char(gl) != code) {
            var charUV = font.getCharCodeUVs(code);
            var glyphOffset:Int = gl.id * cpg;

            pop1(gl.color, glyphOffset, U_OFFSET + 0 * cpv, charUV[3].u);
            pop1(gl.color, glyphOffset, U_OFFSET + 1 * cpv, charUV[0].u);
            pop1(gl.color, glyphOffset, U_OFFSET + 2 * cpv, charUV[1].u);
            pop1(gl.color, glyphOffset, U_OFFSET + 3 * cpv, charUV[2].u);

            pop1(gl.color, glyphOffset, V_OFFSET + 0 * cpv, charUV[3].v);
            pop1(gl.color, glyphOffset, V_OFFSET + 1 * cpv, charUV[0].v);
            pop1(gl.color, glyphOffset, V_OFFSET + 2 * cpv, charUV[1].v);
            pop1(gl.color, glyphOffset, V_OFFSET + 3 * cpv, charUV[2].v);

            gl.charCode = code;
        }
        return code;
    }

    // Paint

    public inline static function get_paint(gl:G) { return gl.paintHex; }

    public inline static function set_paint(gl:G, val:Int) {
        if (get_paint(gl) != val) {

            var paintR = ((val >> 16) & 0xFF) / 0xFF;
            var paintG = ((val >>  8) & 0xFF) / 0xFF;
            var paintB = ((val >>  0) & 0xFF) / 0xFF;
            var glyphOffset:Int = gl.id * ppg;

            pop4(gl.paint, glyphOffset, PR_OFFSET, ppv, paintR);
            pop4(gl.paint, glyphOffset, PG_OFFSET, ppv, paintG);
            pop4(gl.paint, glyphOffset, PB_OFFSET, ppv, paintB);

            gl.paintHex = val;
        }

        return gl.paintHex;
    }

    public inline static function toString(gl:G):String {
        var char = String.fromCharCode(gl.charCode);
        if (!gl.visible) char = char.toLowerCase();
        return char;
    }

    public inline static function transfer(gl:G, shape:VertexArray, color:VertexArray, paint:VertexArray):Void {
        gl.shape = shape;
        gl.color = color;
        gl.paint = paint;
    }

    private inline static function pop1(vec:VertexArray, glyphOffset:Int, propOffset:Int, val:Float):Float {
        vec[glyphOffset + propOffset] = val;
        return val;
    }

    private inline static function pop4(vec:VertexArray, glyphOffset:Int, propOffset:Int, step:Int, val:Float):Float {
        if (vec[glyphOffset + propOffset + 0 * step] != val) {
            vec[glyphOffset + propOffset + 0 * step] = val;
            vec[glyphOffset + propOffset + 1 * step] = val;
            vec[glyphOffset + propOffset + 2 * step] = val;
            vec[glyphOffset + propOffset + 3 * step] = val;
        }
        return val;
    }
}
