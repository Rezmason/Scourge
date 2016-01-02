package net.rezmason.hypertype.core;

#if macro
    import haxe.macro.Context;
    import haxe.macro.Expr;
#else
    import net.rezmason.gl.VertexBuffer;
    import net.rezmason.math.Vec3;
    import net.rezmason.hypertype.core.Almanac.*;
    import net.rezmason.utils.FatChar;
    import net.rezmason.utils.display.SDFFont;
#end

class GlyphUtils {

    static var blank:Int = ' '.charCodeAt(0);

    // Color

    #if !macro
    public inline static function get_r(gl:Glyph) return gl.colorBuf.acc(gl.id * COLOR_FLOATS_PER_GLYPH + R_OFFSET);
    public inline static function set_r(gl:Glyph, v) return pop4(gl.colorBuf, gl.id * COLOR_FLOATS_PER_GLYPH, R_OFFSET, COLOR_FLOATS_PER_VERTEX, v);

    public inline static function get_g(gl:Glyph) return gl.colorBuf.acc(gl.id * COLOR_FLOATS_PER_GLYPH + G_OFFSET);
    public inline static function set_g(gl:Glyph, v) return pop4(gl.colorBuf, gl.id * COLOR_FLOATS_PER_GLYPH, G_OFFSET, COLOR_FLOATS_PER_VERTEX, v);

    public inline static function get_b(gl:Glyph) return gl.colorBuf.acc(gl.id * COLOR_FLOATS_PER_GLYPH + B_OFFSET);
    public inline static function set_b(gl:Glyph, v) return pop4(gl.colorBuf, gl.id * COLOR_FLOATS_PER_GLYPH, B_OFFSET, COLOR_FLOATS_PER_VERTEX, v);

    public inline static function get_i(gl:Glyph) return gl.colorBuf.acc(gl.id * COLOR_FLOATS_PER_GLYPH + I_OFFSET);
    public inline static function set_i(gl:Glyph, v) return pop4(gl.colorBuf, gl.id * COLOR_FLOATS_PER_GLYPH, I_OFFSET, COLOR_FLOATS_PER_VERTEX, v);

    public inline static function get_f(gl:Glyph) return gl.colorBuf.acc(gl.id * COLOR_FLOATS_PER_GLYPH + F_OFFSET);
    public inline static function set_f(gl:Glyph, v) return pop4(gl.colorBuf, gl.id * COLOR_FLOATS_PER_GLYPH, F_OFFSET, COLOR_FLOATS_PER_VERTEX, v);

    public inline static function get_a(gl:Glyph) return gl.colorBuf.acc(gl.id * COLOR_FLOATS_PER_GLYPH + A_OFFSET);
    public inline static function set_a(gl:Glyph, v) return pop4(gl.colorBuf, gl.id * COLOR_FLOATS_PER_GLYPH, A_OFFSET, COLOR_FLOATS_PER_VERTEX, v);

    public inline static function set_rgb(gl:Glyph, r, g, b) {
        set_r(gl, r);
        set_g(gl, g);
        set_b(gl, b);
    }

    public inline static function get_color(gl:Glyph):Vec3 {
        if (gl.color == null) gl.color = new Vec3(0, 0, 0);
        gl.color.r = get_r(gl);
        gl.color.g = get_g(gl);
        gl.color.b = get_b(gl);
        return gl.color;
    }

    public inline static function set_color(gl:Glyph, color:Vec3) {
        set_r(gl, color.r);
        set_g(gl, color.g);
        set_b(gl, color.b);
    }

    public inline static function add_color(gl:Glyph, val:Float) {
        set_r(gl, get_r(gl) + val);
        set_g(gl, get_g(gl) + val);
        set_b(gl, get_b(gl) + val);
    }

    public inline static function mult_color(gl:Glyph, val:Float) {
        set_r(gl, get_r(gl) * val);
        set_g(gl, get_g(gl) * val);
        set_b(gl, get_b(gl) * val);
    }

    public inline static function set_fx(gl:Glyph, i, f, a) {
        set_i(gl, i);
        set_f(gl, f);
        set_a(gl, a);
    }

    public inline static function createGlyph():Glyph {
        var gl = new Glyph();
        gl.geometryBuf = new VertexBuffer(VERTICES_PER_GLYPH, GEOMETRY_FLOATS_PER_VERTEX);
        gl.colorBuf = new VertexBuffer(VERTICES_PER_GLYPH, COLOR_FLOATS_PER_VERTEX);
        gl.paintBuf = new VertexBuffer(VERTICES_PER_GLYPH, PAINT_FLOATS_PER_VERTEX);
        init(gl);
        return gl;
    }

    public inline static function clone(src:Glyph):Glyph {
        var gl = createGlyph();
        copyFrom(gl, src);
        return gl;
    }

    public static function copyFrom(gl:Glyph, src:Glyph):Glyph {
        var destGeometryAddress = gl.id * GEOMETRY_FLOATS_PER_GLYPH;
        var destColorAddress = gl.id * COLOR_FLOATS_PER_GLYPH;
        var destPaintAddress = gl.id * PAINT_FLOATS_PER_GLYPH;
        var srcGeometryAddress = src.id * GEOMETRY_FLOATS_PER_GLYPH;
        var srcColorAddress = src.id * COLOR_FLOATS_PER_GLYPH;
        var srcPaintAddress = src.id * PAINT_FLOATS_PER_GLYPH;
        for (ike in 0...GEOMETRY_FLOATS_PER_GLYPH) gl.geometryBuf.mod(destGeometryAddress + ike, src.geometryBuf.acc(srcGeometryAddress + ike));
        for (ike in 0...COLOR_FLOATS_PER_GLYPH) gl.colorBuf.mod(destColorAddress + ike, src.colorBuf.acc(srcColorAddress + ike));
        for (ike in 0...PAINT_FLOATS_PER_GLYPH) gl.paintBuf.mod(destPaintAddress + ike, src.paintBuf.acc(srcPaintAddress + ike));
        gl.paintHex = src.paintHex;
        gl.charCode = src.charCode;
        gl.font = src.font;
        return gl;
    }

    // Shape

    public inline static function get_x(gl:Glyph) return gl.geometryBuf.acc(gl.id * GEOMETRY_FLOATS_PER_GLYPH + X_OFFSET);
    public inline static function set_x(gl:Glyph, v) return pop4(gl.geometryBuf, gl.id * GEOMETRY_FLOATS_PER_GLYPH, X_OFFSET, GEOMETRY_FLOATS_PER_VERTEX, v);
    public inline static function get_y(gl:Glyph) return gl.geometryBuf.acc(gl.id * GEOMETRY_FLOATS_PER_GLYPH + Y_OFFSET);
    public inline static function set_y(gl:Glyph, v) return pop4(gl.geometryBuf, gl.id * GEOMETRY_FLOATS_PER_GLYPH, Y_OFFSET, GEOMETRY_FLOATS_PER_VERTEX, v);
    public inline static function get_z(gl:Glyph) return gl.geometryBuf.acc(gl.id * GEOMETRY_FLOATS_PER_GLYPH + Z_OFFSET);
    public inline static function set_z(gl:Glyph, v) return pop4(gl.geometryBuf, gl.id * GEOMETRY_FLOATS_PER_GLYPH, Z_OFFSET, GEOMETRY_FLOATS_PER_VERTEX, v);

    public inline static function get_s(gl:Glyph) return gl.geometryBuf.acc(gl.id * GEOMETRY_FLOATS_PER_GLYPH + S_OFFSET);
    public inline static function set_s(gl:Glyph, v) return pop4(gl.geometryBuf, gl.id * GEOMETRY_FLOATS_PER_GLYPH, S_OFFSET, GEOMETRY_FLOATS_PER_VERTEX, v);

    public inline static function get_p(gl:Glyph) return gl.geometryBuf.acc(gl.id * GEOMETRY_FLOATS_PER_GLYPH + P_OFFSET);
    public inline static function set_p(gl:Glyph, v) return pop4(gl.geometryBuf, gl.id * GEOMETRY_FLOATS_PER_GLYPH, P_OFFSET, GEOMETRY_FLOATS_PER_VERTEX, v);

    public inline static function get_h(gl:Glyph) return gl.geometryBuf.acc(gl.id * GEOMETRY_FLOATS_PER_GLYPH + H_OFFSET);
    public inline static function set_h(gl:Glyph, v) return pop4(gl.geometryBuf, gl.id * GEOMETRY_FLOATS_PER_GLYPH, H_OFFSET, GEOMETRY_FLOATS_PER_VERTEX, v);

    public inline static function set_xyz(gl:Glyph, x, y, z) {
        set_x(gl, x);
        set_y(gl, y);
        set_z(gl, z);
    }

    public inline static function set_pos(gl:Glyph, pos:Vec3) {
        set_x(gl, pos.x);
        set_y(gl, pos.y);
        set_z(gl, pos.z);
    }

    public inline static function set_distort(gl:Glyph, h, s, p) {
        set_h(gl, h);
        set_s(gl, s);
        set_p(gl, p);
    }

    // Character

    public inline static function get_font(gl:Glyph) return gl.font;

    public inline static function set_font(gl:Glyph, font:SDFFont) {
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
            gl.charCode = code;
            var u = 0.;
            var v = 0.;
            if (code != -1 && gl.font != null) {
                var charCenterUV = gl.font.getCharCodeCenterUV(code);
                if (charCenterUV != null) {
                    u = charCenterUV.u;
                    v = charCenterUV.v;
                }
                #if debug
                    else trace('Unsupported character $code');
                #end
            }
            
            var glyphOffset:Int = gl.id * COLOR_FLOATS_PER_GLYPH;
            pop4(gl.colorBuf, glyphOffset, U_OFFSET, COLOR_FLOATS_PER_VERTEX, u);
            pop4(gl.colorBuf, glyphOffset, V_OFFSET, COLOR_FLOATS_PER_VERTEX, v);
        }
        return code;
    }

    // Paint

    public inline static function get_paint(gl:Glyph) return gl.paintHex;

    public inline static function set_paint(gl:Glyph, val:Int) {
        #if debug if (val > 0xFFFF) throw 'Glyph cannot be painted color ${Vec3.fromHex(val)}'; #end
        if (gl.paintHex != val) {

            var paintR = ((val >>  8) & 0xFF) / 0xFF;
            var paintG = ((val >>  0) & 0xFF) / 0xFF;
            var glyphOffset:Int = gl.id * PAINT_FLOATS_PER_GLYPH;

            pop4(gl.paintBuf, glyphOffset, PAINT_R_OFFSET, PAINT_FLOATS_PER_VERTEX, paintR);
            pop4(gl.paintBuf, glyphOffset, PAINT_G_OFFSET, PAINT_FLOATS_PER_VERTEX, paintG);

            gl.paintHex = val;
        }

        return gl.paintHex;
    }

    public inline static function get_paint_s(gl:Glyph) return gl.paintBuf.acc(gl.id * PAINT_FLOATS_PER_GLYPH + PAINT_S_OFFSET);
    public inline static function set_paint_s(gl:Glyph, v) return pop4(gl.paintBuf, gl.id * PAINT_FLOATS_PER_GLYPH, PAINT_S_OFFSET, PAINT_FLOATS_PER_VERTEX, v);

    public inline static function get_paint_h(gl:Glyph) return gl.paintBuf.acc(gl.id * PAINT_FLOATS_PER_GLYPH + PAINT_H_OFFSET);
    public inline static function set_paint_h(gl:Glyph, v) return pop4(gl.paintBuf, gl.id * PAINT_FLOATS_PER_GLYPH, PAINT_H_OFFSET, PAINT_FLOATS_PER_VERTEX, v);

    public inline static function init(gl:Glyph):Void {
        // corner H
        var glyphOffset:Int = gl.id * GEOMETRY_FLOATS_PER_GLYPH;
        pop1(gl.geometryBuf, glyphOffset, CORNER_H_OFFSET + 0 * GEOMETRY_FLOATS_PER_VERTEX, -1);
        pop1(gl.geometryBuf, glyphOffset, CORNER_H_OFFSET + 1 * GEOMETRY_FLOATS_PER_VERTEX,  1);
        pop1(gl.geometryBuf, glyphOffset, CORNER_H_OFFSET + 2 * GEOMETRY_FLOATS_PER_VERTEX,  1);
        pop1(gl.geometryBuf, glyphOffset, CORNER_H_OFFSET + 3 * GEOMETRY_FLOATS_PER_VERTEX, -1);
        // corner V
        pop1(gl.geometryBuf, glyphOffset, CORNER_V_OFFSET + 0 * GEOMETRY_FLOATS_PER_VERTEX,  1);
        pop1(gl.geometryBuf, glyphOffset, CORNER_V_OFFSET + 1 * GEOMETRY_FLOATS_PER_VERTEX,  1);
        pop1(gl.geometryBuf, glyphOffset, CORNER_V_OFFSET + 2 * GEOMETRY_FLOATS_PER_VERTEX, -1);
        pop1(gl.geometryBuf, glyphOffset, CORNER_V_OFFSET + 3 * GEOMETRY_FLOATS_PER_VERTEX, -1);

        set_paint(gl, 0);
        set_paint_h(gl, 1);
        set_paint_s(gl, 1);

        reset(gl);
    }

    public inline static function reset(gl:Glyph):Glyph {
        set_distort(gl, 1, 1, 0); // h, s, p
        set_xyz(gl, 0, 0, 0); // x, y, z
        set_rgb(gl, 1, 1, 1); // r, g, b
        set_fx(gl, 0, 0, 0); // i, f, a
        // We don't reset the font.
        set_char(gl, -1);
        // We don't reset the paint.
        return gl;
    }

    public inline static function toString(gl:Glyph):String return String.fromCharCode(gl.charCode);

    private inline static function pop1(vec:VertexBuffer, glyphOffset:Int, propOffset:Int, val:Float):Float {
        return vec.mod(glyphOffset + propOffset, val);
    }

    private inline static function pop4(vec:VertexBuffer, glyphOffset:Int, propOffset:Int, step:Int, val:Float):Float {
        #if (debug && cpp)
            if (Math.isNaN(val)) throw "NaN value.";
        #elseif debug
            if (!(val == val)) throw "NaN value.";
        #end

        if (vec.acc(glyphOffset + propOffset + 0 * step) != val) {
            vec.mod(glyphOffset + propOffset + 0 * step, val);
            vec.mod(glyphOffset + propOffset + 1 * step, val);
            vec.mod(glyphOffset + propOffset + 2 * step, val);
            vec.mod(glyphOffset + propOffset + 3 * step, val);
        }
        return val;
    }
    #end

    macro public static function SET(gl:Expr, params:Expr):Expr {
        switch (Context.typeExpr(gl).t) {
            case TInst(ref, _) if (ref.get().name == 'Glyph'):
            case _: throw 'gl argument must be a Glyph.';
        }

        var expressions = [macro var __gl__ = ${gl}];
        switch (params.expr) {
            case EObjectDecl(fields):
                for (field in fields) {
                    expressions.push(macro $p{['GlyphUtils', 'set_' + field.field]}(__gl__, ${field.expr}));
                }
            case EBlock(exprs) if (exprs.length == 0):
            case _: throw 'params argument must be an anonymous object.';
        }
        expressions.push(macro __gl__);
        return macro $b{expressions};
    }
}
