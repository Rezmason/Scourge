package net.rezmason.scourge.textview.core;

import net.rezmason.gl.Data;

import net.rezmason.utils.FatChar;
import net.rezmason.utils.display.FlatFont;
import net.rezmason.scourge.textview.core.Almanac.*;

class GlyphUtils {

    static var blank:Int = ' '.charCodeAt(0);

    // Color

    public inline static function get_r(gl:Glyph) return gl.color[gl.id * COLOR_FLOATS_PER_GLYPH + R_OFFSET];
    public inline static function set_r(gl:Glyph, v) return pop4(gl.color, gl.id * COLOR_FLOATS_PER_GLYPH, R_OFFSET, COLOR_FLOATS_PER_VERTEX, v);

    public inline static function get_g(gl:Glyph) return gl.color[gl.id * COLOR_FLOATS_PER_GLYPH + G_OFFSET];
    public inline static function set_g(gl:Glyph, v) return pop4(gl.color, gl.id * COLOR_FLOATS_PER_GLYPH, G_OFFSET, COLOR_FLOATS_PER_VERTEX, v);

    public inline static function get_b(gl:Glyph) return gl.color[gl.id * COLOR_FLOATS_PER_GLYPH + B_OFFSET];
    public inline static function set_b(gl:Glyph, v) return pop4(gl.color, gl.id * COLOR_FLOATS_PER_GLYPH, B_OFFSET, COLOR_FLOATS_PER_VERTEX, v);

    public inline static function get_i(gl:Glyph) return gl.color[gl.id * COLOR_FLOATS_PER_GLYPH + I_OFFSET];
    public inline static function set_i(gl:Glyph, v) return pop4(gl.color, gl.id * COLOR_FLOATS_PER_GLYPH, I_OFFSET, COLOR_FLOATS_PER_VERTEX, v);

    public inline static function get_f(gl:Glyph) return gl.color[gl.id * COLOR_FLOATS_PER_GLYPH + F_OFFSET];
    public inline static function set_f(gl:Glyph, v) return pop4(gl.color, gl.id * COLOR_FLOATS_PER_GLYPH, F_OFFSET, COLOR_FLOATS_PER_VERTEX, v);

    public inline static function set_rgb(gl:Glyph, r, g, b) {
        set_r(gl, r);
        set_g(gl, g);
        set_b(gl, b);
    }

    public inline static function get_color(gl:Glyph):Color {
        return {
            r: get_r(gl),
            g: get_g(gl),
            b: get_b(gl),
        };
    }

    public inline static function set_color(gl:Glyph, color:Color) {
        set_r(gl, color.r);
        set_g(gl, color.g);
        set_b(gl, color.b);
    }

    // Shape

    public inline static function get_x(gl:Glyph) return gl.shape[gl.id * SHAPE_FLOATS_PER_GLYPH + X_OFFSET];
    public inline static function set_x(gl:Glyph, v) return pop4(gl.shape, gl.id * SHAPE_FLOATS_PER_GLYPH, X_OFFSET, SHAPE_FLOATS_PER_VERTEX, v);
    public inline static function get_y(gl:Glyph) return gl.shape[gl.id * SHAPE_FLOATS_PER_GLYPH + Y_OFFSET];
    public inline static function set_y(gl:Glyph, v) return pop4(gl.shape, gl.id * SHAPE_FLOATS_PER_GLYPH, Y_OFFSET, SHAPE_FLOATS_PER_VERTEX, v);
    public inline static function get_z(gl:Glyph) return gl.shape[gl.id * SHAPE_FLOATS_PER_GLYPH + Z_OFFSET];
    public inline static function set_z(gl:Glyph, v) return pop4(gl.shape, gl.id * SHAPE_FLOATS_PER_GLYPH, Z_OFFSET, SHAPE_FLOATS_PER_VERTEX, v);

    public inline static function get_s(gl:Glyph) return gl.shape[gl.id * SHAPE_FLOATS_PER_GLYPH + S_OFFSET];
    public inline static function set_s(gl:Glyph, v) return pop4(gl.shape, gl.id * SHAPE_FLOATS_PER_GLYPH, S_OFFSET, SHAPE_FLOATS_PER_VERTEX, v);

    public inline static function get_p(gl:Glyph) return gl.shape[gl.id * SHAPE_FLOATS_PER_GLYPH + P_OFFSET];
    public inline static function set_p(gl:Glyph, v) return pop4(gl.shape, gl.id * SHAPE_FLOATS_PER_GLYPH, P_OFFSET, SHAPE_FLOATS_PER_VERTEX, v);

    public inline static function set_shape(gl:Glyph, x, y, z, s, p) {
        set_pos(gl, x, y, z);
        set_s(gl, s);
        set_p(gl, p);
    }

    public inline static function set_pos(gl:Glyph, x, y, z) {
        set_x(gl, x);
        set_y(gl, y);
        set_z(gl, z);
    }

    public inline static function makeCorners(gl:Glyph):Void {
        var glyphOffset:Int = gl.id * SHAPE_FLOATS_PER_GLYPH;
        pop1(gl.shape, glyphOffset, A_OFFSET + 0 * SHAPE_FLOATS_PER_VERTEX, 0);
        pop1(gl.shape, glyphOffset, A_OFFSET + 1 * SHAPE_FLOATS_PER_VERTEX, 0);
        pop1(gl.shape, glyphOffset, A_OFFSET + 2 * SHAPE_FLOATS_PER_VERTEX, 1);
        pop1(gl.shape, glyphOffset, A_OFFSET + 3 * SHAPE_FLOATS_PER_VERTEX, 1);

        pop1(gl.shape, glyphOffset, D_OFFSET + 0 * SHAPE_FLOATS_PER_VERTEX, 0);
        pop1(gl.shape, glyphOffset, D_OFFSET + 1 * SHAPE_FLOATS_PER_VERTEX, 1);
        pop1(gl.shape, glyphOffset, D_OFFSET + 2 * SHAPE_FLOATS_PER_VERTEX, 1);
        pop1(gl.shape, glyphOffset, D_OFFSET + 3 * SHAPE_FLOATS_PER_VERTEX, 0);
    }

    // Character

    public inline static function get_char(gl:Glyph) return gl.charCode;

    public inline static function set_char(gl:Glyph, code:Int, font:FlatFont) {
        if (get_char(gl) != code) {

            var glyphOffset:Int = gl.id * COLOR_FLOATS_PER_GLYPH;

            if (code == -1) {
                pop4(gl.color, glyphOffset, U_OFFSET, COLOR_FLOATS_PER_VERTEX, 0);
                pop4(gl.color, glyphOffset, V_OFFSET, COLOR_FLOATS_PER_VERTEX, 0);
                gl.charCode = -1;
            } else {
                var charUV = font.getCharCodeUVs(code);

                pop1(gl.color, glyphOffset, U_OFFSET + 0 * COLOR_FLOATS_PER_VERTEX, charUV[3].u);
                pop1(gl.color, glyphOffset, U_OFFSET + 1 * COLOR_FLOATS_PER_VERTEX, charUV[0].u);
                pop1(gl.color, glyphOffset, U_OFFSET + 2 * COLOR_FLOATS_PER_VERTEX, charUV[1].u);
                pop1(gl.color, glyphOffset, U_OFFSET + 3 * COLOR_FLOATS_PER_VERTEX, charUV[2].u);

                pop1(gl.color, glyphOffset, V_OFFSET + 0 * COLOR_FLOATS_PER_VERTEX, charUV[3].v);
                pop1(gl.color, glyphOffset, V_OFFSET + 1 * COLOR_FLOATS_PER_VERTEX, charUV[0].v);
                pop1(gl.color, glyphOffset, V_OFFSET + 2 * COLOR_FLOATS_PER_VERTEX, charUV[1].v);
                pop1(gl.color, glyphOffset, V_OFFSET + 3 * COLOR_FLOATS_PER_VERTEX, charUV[2].v);
                gl.charCode = code;
            }
        }
        return code;
    }

    // Paint

    public inline static function get_paint(gl:Glyph) return gl.paintHex;

    public inline static function set_paint(gl:Glyph, val:Int) {
        if (get_paint(gl) != val) {

            var paintR = ((val >> 16) & 0xFF) / 0xFF;
            var paintG = ((val >>  8) & 0xFF) / 0xFF;
            var paintB = ((val >>  0) & 0xFF) / 0xFF;
            var glyphOffset:Int = gl.id * PAINT_FLOATS_PER_GLYPH;

            pop4(gl.paint, glyphOffset, PR_OFFSET, PAINT_FLOATS_PER_VERTEX, paintR);
            pop4(gl.paint, glyphOffset, PG_OFFSET, PAINT_FLOATS_PER_VERTEX, paintG);
            pop4(gl.paint, glyphOffset, PB_OFFSET, PAINT_FLOATS_PER_VERTEX, paintB);

            gl.paintHex = val;
        }

        return gl.paintHex;
    }

    public inline static function transfer(gl:Glyph, shape:VertexArray, color:VertexArray, paint:VertexArray):Void {
        gl.shape = shape;
        gl.color = color;
        gl.paint = paint;

        makeCorners(gl);

        gl.charCode = 0;
        gl.paintHex = 0;

        set_paint(gl, gl.paintHex);

        pop4(gl.color, gl.id * COLOR_FLOATS_PER_GLYPH, U_OFFSET, COLOR_FLOATS_PER_VERTEX, 0);
        pop4(gl.color, gl.id * COLOR_FLOATS_PER_GLYPH, V_OFFSET, COLOR_FLOATS_PER_VERTEX, 0);
    }

    public inline static function reset(gl:Glyph):Void {
        set_rgb(gl, 1, 1, 1);
        set_s(gl, 1);
        set_f(gl, 0.5);
        set_char(gl, -1, null);
    }

    public inline static function toString(gl:Glyph):String return String.fromCharCode(gl.charCode);

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
