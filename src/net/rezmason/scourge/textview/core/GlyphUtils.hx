package net.rezmason.scourge.textview.core;

import net.rezmason.gl.Types;

import net.rezmason.utils.FatChar;
import net.rezmason.utils.FlatFont;

typedef G = Glyph;

class GlyphUtils {

    inline static var rOff:Int = Almanac.R_OFFSET;
    inline static var gOff:Int = Almanac.G_OFFSET;
    inline static var bOff:Int = Almanac.B_OFFSET;
    inline static var uOff:Int = Almanac.U_OFFSET;
    inline static var vOff:Int = Almanac.V_OFFSET;
    inline static var iOff:Int = Almanac.I_OFFSET;
    inline static var fOff:Int = Almanac.F_OFFSET;

    inline static var xOff:Int = Almanac.X_OFFSET;
    inline static var yOff:Int = Almanac.Y_OFFSET;
    inline static var zOff:Int = Almanac.Z_OFFSET;
    inline static var aOff:Int = Almanac.A_OFFSET;
    inline static var dOff:Int = Almanac.D_OFFSET;
    inline static var sOff:Int = Almanac.S_OFFSET;
    inline static var pOff:Int = Almanac.P_OFFSET;

    inline static var prOff:Int = Almanac.PR_OFFSET;
    inline static var pgOff:Int = Almanac.PG_OFFSET;
    inline static var pbOff:Int = Almanac.PB_OFFSET;

    static var blank:Int = ' '.charCodeAt(0);

    inline static var spv:Int = Almanac.SHAPE_FLOATS_PER_VERTEX;
    inline static var cpv:Int = Almanac.COLOR_FLOATS_PER_VERTEX;
    inline static var ppv:Int = Almanac.PAINT_FLOATS_PER_VERTEX;

    inline static var spg:Int = Almanac.SHAPE_FLOATS_PER_GLYPH;
    inline static var cpg:Int = Almanac.COLOR_FLOATS_PER_GLYPH;
    inline static var ppg:Int = Almanac.PAINT_FLOATS_PER_GLYPH;

    // Color

    public inline static function get_r(gl:G) { return gl.color[gl.id * cpg + rOff]; }
    public inline static function set_r(gl:G, v) { return pop4(gl.color, gl.id * cpg, rOff, cpv, v); }

    public inline static function get_g(gl:G) { return gl.color[gl.id * cpg + gOff]; }
    public inline static function set_g(gl:G, v) { return pop4(gl.color, gl.id * cpg, gOff, cpv, v); }

    public inline static function get_b(gl:G) { return gl.color[gl.id * cpg + bOff]; }
    public inline static function set_b(gl:G, v) { return pop4(gl.color, gl.id * cpg, bOff, cpv, v); }

    public inline static function get_i(gl:G) { return gl.color[gl.id * cpg + iOff]; }
    public inline static function set_i(gl:G, v) { return pop4(gl.color, gl.id * cpg, iOff, cpv, v); }

    public inline static function get_f(gl:G) { return gl.color[gl.id * cpg + fOff]; }
    public inline static function set_f(gl:G, v) { return pop4(gl.color, gl.id * cpg, fOff, cpv, v); }

    public inline static function set_rgb(gl:G, r, g, b) {
        set_r(gl, r);
        set_g(gl, g);
        set_b(gl, b);
    }

    public inline static function get_color(gl:G):Color {
        return {
            r: get_r(gl),
            g: get_g(gl),
            b: get_b(gl),
        };
    }

    public inline static function set_color(gl:G, color:Color) {
        set_r(gl, color.r);
        set_g(gl, color.g);
        set_b(gl, color.b);
    }

    // Shape

    public inline static function get_x(gl:G) { return gl.shape[gl.id * spg + xOff]; }
    public inline static function set_x(gl:G, v) { return pop4(gl.shape, gl.id * spg, xOff, spv, v); }
    public inline static function get_y(gl:G) { return gl.shape[gl.id * spg + yOff]; }
    public inline static function set_y(gl:G, v) { return pop4(gl.shape, gl.id * spg, yOff, spv, v); }
    public inline static function get_z(gl:G) { return gl.shape[gl.id * spg + zOff]; }
    public inline static function set_z(gl:G, v) { return pop4(gl.shape, gl.id * spg, zOff, spv, v); }

    public inline static function get_s(gl:G) { return gl.shape[gl.id * spg + sOff]; }
    public inline static function set_s(gl:G, v) { return pop4(gl.shape, gl.id * spg, sOff, spv, v); }

    public inline static function get_p(gl:G) { return gl.shape[gl.id * spg + pOff]; }
    public inline static function set_p(gl:G, v) { return pop4(gl.shape, gl.id * spg, pOff, spv, v); }

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
        pop1(gl.shape, glyphOffset, aOff + 0 * spv, 0);
        pop1(gl.shape, glyphOffset, aOff + 1 * spv, 0);
        pop1(gl.shape, glyphOffset, aOff + 2 * spv, 1);
        pop1(gl.shape, glyphOffset, aOff + 3 * spv, 1);

        pop1(gl.shape, glyphOffset, dOff + 0 * spv, 0);
        pop1(gl.shape, glyphOffset, dOff + 1 * spv, 1);
        pop1(gl.shape, glyphOffset, dOff + 2 * spv, 1);
        pop1(gl.shape, glyphOffset, dOff + 3 * spv, 0);
    }

    // Character

    public inline static function get_char(gl:G) { return gl.charCode; }

    public inline static function set_char(gl:G, code, font:FlatFont) {
        if (get_char(gl) != code) {
            var charUV = font.getCharCodeUVs(code);
            var glyphOffset:Int = gl.id * cpg;

            pop1(gl.color, glyphOffset, uOff + 0 * cpv, charUV[3].u);
            pop1(gl.color, glyphOffset, uOff + 1 * cpv, charUV[0].u);
            pop1(gl.color, glyphOffset, uOff + 2 * cpv, charUV[1].u);
            pop1(gl.color, glyphOffset, uOff + 3 * cpv, charUV[2].u);

            pop1(gl.color, glyphOffset, vOff + 0 * cpv, charUV[3].v);
            pop1(gl.color, glyphOffset, vOff + 1 * cpv, charUV[0].v);
            pop1(gl.color, glyphOffset, vOff + 2 * cpv, charUV[1].v);
            pop1(gl.color, glyphOffset, vOff + 3 * cpv, charUV[2].v);

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

            pop4(gl.paint, glyphOffset, prOff, ppv, paintR);
            pop4(gl.paint, glyphOffset, pgOff, ppv, paintG);
            pop4(gl.paint, glyphOffset, pbOff, ppv, paintB);

            gl.paintHex = val;
        }

        return gl.paintHex;
    }

    public inline static function transfer(gl:G, shape:VertexArray, color:VertexArray, paint:VertexArray):Void {
        gl.shape = shape;
        gl.color = color;
        gl.paint = paint;

        makeCorners(gl);

        gl.charCode = 0;
        gl.paintHex = 0;

        set_paint(gl, gl.paintHex);

        pop4(gl.color, gl.id * cpg, uOff, cpv, 0);
        pop4(gl.color, gl.id * cpg, vOff, cpv, 0);
    }

    public inline static function toString(gl:G):String return String.fromCharCode(gl.charCode);

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
