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

    public inline static function get_a(gl:Glyph) return gl.color[gl.id * COLOR_FLOATS_PER_GLYPH + A_OFFSET];
    public inline static function set_a(gl:Glyph, v) return pop4(gl.color, gl.id * COLOR_FLOATS_PER_GLYPH, A_OFFSET, COLOR_FLOATS_PER_VERTEX, v);

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

    public inline static function set_fx(gl:Glyph, i, f, a) {
        set_i(gl, i);
        set_f(gl, f);
        set_a(gl, a);
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

    public inline static function get_h(gl:Glyph) return gl.shape[gl.id * SHAPE_FLOATS_PER_GLYPH + H_OFFSET];
    public inline static function set_h(gl:Glyph, v) return pop4(gl.shape, gl.id * SHAPE_FLOATS_PER_GLYPH, H_OFFSET, SHAPE_FLOATS_PER_VERTEX, v);

    public inline static function set_xyz(gl:Glyph, x, y, z) {
        set_x(gl, x);
        set_y(gl, y);
        set_z(gl, z);
    }

    public inline static function set_pos(gl:Glyph, pos:XYZ) {
        set_x(gl, pos.x);
        set_y(gl, pos.y);
        set_z(gl, pos.z);
    }

    public inline static function set_distort(gl:Glyph, h, s, p) {
        set_h(gl, h);
        set_s(gl, s);
        set_p(gl, p);
    }

    public inline static function makeCorners(gl:Glyph):Void {
        var glyphOffset:Int = gl.id * SHAPE_FLOATS_PER_GLYPH;
        pop1(gl.shape, glyphOffset, CORNER_H_OFFSET + 0 * SHAPE_FLOATS_PER_VERTEX, -1);
        pop1(gl.shape, glyphOffset, CORNER_H_OFFSET + 1 * SHAPE_FLOATS_PER_VERTEX, -1);
        pop1(gl.shape, glyphOffset, CORNER_H_OFFSET + 2 * SHAPE_FLOATS_PER_VERTEX,  1);
        pop1(gl.shape, glyphOffset, CORNER_H_OFFSET + 3 * SHAPE_FLOATS_PER_VERTEX,  1);

        pop1(gl.shape, glyphOffset, CORNER_V_OFFSET + 0 * SHAPE_FLOATS_PER_VERTEX, -1);
        pop1(gl.shape, glyphOffset, CORNER_V_OFFSET + 1 * SHAPE_FLOATS_PER_VERTEX,  1);
        pop1(gl.shape, glyphOffset, CORNER_V_OFFSET + 2 * SHAPE_FLOATS_PER_VERTEX,  1);
        pop1(gl.shape, glyphOffset, CORNER_V_OFFSET + 3 * SHAPE_FLOATS_PER_VERTEX, -1);
    }

    // Character

    public inline static function get_font(gl:Glyph) return gl.font;

    public inline static function set_font(gl:Glyph, font:FlatFont) {
        if (gl.font != font) {
            gl.font = font;
            if (gl.charCode != -1) {
                var char = gl.charCode;
                gl.charCode = -1;
                set_char(gl, char);
            }
        }
    }

    public inline static function get_char(gl:Glyph) return gl.charCode;

    public inline static function set_char(gl:Glyph, code:Int) {
        if (get_char(gl) != code) {

            var glyphOffset:Int = gl.id * COLOR_FLOATS_PER_GLYPH;

            if (code == -1) {
                pop4(gl.color, glyphOffset, U_OFFSET, COLOR_FLOATS_PER_VERTEX, 0);
                pop4(gl.color, glyphOffset, V_OFFSET, COLOR_FLOATS_PER_VERTEX, 0);
                gl.charCode = -1;
            } else {
                if (gl.font != null) {
                    var charUVs:Array<UV> = gl.font.getCharCodeUVs(code);

                    pop1(gl.color, glyphOffset, U_OFFSET + 0 * COLOR_FLOATS_PER_VERTEX, charUVs[3].u);
                    pop1(gl.color, glyphOffset, U_OFFSET + 1 * COLOR_FLOATS_PER_VERTEX, charUVs[0].u);
                    pop1(gl.color, glyphOffset, U_OFFSET + 2 * COLOR_FLOATS_PER_VERTEX, charUVs[1].u);
                    pop1(gl.color, glyphOffset, U_OFFSET + 3 * COLOR_FLOATS_PER_VERTEX, charUVs[2].u);

                    pop1(gl.color, glyphOffset, V_OFFSET + 0 * COLOR_FLOATS_PER_VERTEX, charUVs[3].v);
                    pop1(gl.color, glyphOffset, V_OFFSET + 1 * COLOR_FLOATS_PER_VERTEX, charUVs[0].v);
                    pop1(gl.color, glyphOffset, V_OFFSET + 2 * COLOR_FLOATS_PER_VERTEX, charUVs[1].v);
                    pop1(gl.color, glyphOffset, V_OFFSET + 3 * COLOR_FLOATS_PER_VERTEX, charUVs[2].v);
                } else {
                    pop4(gl.color, glyphOffset, U_OFFSET, COLOR_FLOATS_PER_VERTEX, 0);
                    pop4(gl.color, glyphOffset, V_OFFSET, COLOR_FLOATS_PER_VERTEX, 0);
                }
                gl.charCode = code;
            }
        }
        return code;
    }

    // Paint

    public inline static function get_paint(gl:Glyph) return gl.paintHex;

    public inline static function set_paint(gl:Glyph, val:Int) {
        #if debug if (val > 0xFFFF) throw 'Glyph cannot be painted color ${Colors.fromHex(val)}'; #end
        if (gl.paintHex != val) {

            var paintR = ((val >>  8) & 0xFF) / 0xFF;
            var paintG = ((val >>  0) & 0xFF) / 0xFF;
            var glyphOffset:Int = gl.id * PAINT_FLOATS_PER_GLYPH;

            pop4(gl.paint, glyphOffset, PR_OFFSET, PAINT_FLOATS_PER_VERTEX, paintR);
            pop4(gl.paint, glyphOffset, PG_OFFSET, PAINT_FLOATS_PER_VERTEX, paintG);

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
        set_distort(gl, 1, 1, 0);
        set_xyz(gl, 0, 0, 0);
        set_rgb(gl, 1, 1, 1);
        set_fx(gl, 0, 0.5, 0);
        // We don't reset the font.
        set_char(gl, -1);
    }

    public inline static function toString(gl:Glyph):String return String.fromCharCode(gl.charCode);

    private inline static function pop1(vec:VertexArray, glyphOffset:Int, propOffset:Int, val:Float):Float {
        vec[glyphOffset + propOffset] = val;
        return val;
    }

    private inline static function pop4(vec:VertexArray, glyphOffset:Int, propOffset:Int, step:Int, val:Float):Float {
        #if debug
            if (Math.isNaN(val)) throw "NaN value.";
        #end

        if (vec[glyphOffset + propOffset + 0 * step] != val) {
            vec[glyphOffset + propOffset + 0 * step] = val;
            vec[glyphOffset + propOffset + 1 * step] = val;
            vec[glyphOffset + propOffset + 2 * step] = val;
            vec[glyphOffset + propOffset + 3 * step] = val;
        }
        return val;
    }
}
