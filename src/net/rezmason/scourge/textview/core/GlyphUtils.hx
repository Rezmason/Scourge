package net.rezmason.scourge.textview.core;

import net.rezmason.utils.FatChar;
import net.rezmason.utils.FlatFont;

class GlyphUtils {

    inline static var spv = Almanac.SHAPE_FLOATS_PER_VERTEX;
    inline static var cpv = Almanac.COLOR_FLOATS_PER_VERTEX;
    inline static var ppv = Almanac.PAINT_FLOATS_PER_VERTEX;

    // Color

    public inline static function get_r(g) { return g.color[0]; }
    public inline static function set_r(g, v) { mark(g); return pop4(g.color, 0, cpv, v); }

    public inline static function get_g(g) { return g.color[1]; }
    public inline static function set_g(g, v) { mark(g); return pop4(g.color, 1, cpv, v); }

    public inline static function get_b(g) { return g.color[2]; }
    public inline static function set_b(g, v) { mark(g); return pop4(g.color, 2, cpv, v); }

    public inline static function get_i(g) { return g.color[5]; }
    public inline static function set_i(g, v) { mark(g); return pop4(g.color, 5, cpv, v); }

    public inline static function set_color(glyph:Glyph, r, g, b) {
        set_r(glyph, r);
        set_g(glyph, g);
        set_b(glyph, b);
    }

    // Shape

    public inline static function get_x(g) { return g.shape[0]; }
    public inline static function set_x(g, v) { mark(g); return pop4(g.shape, 0, spv, v); }
    public inline static function get_y(g) { return g.shape[1]; }
    public inline static function set_y(g, v) { mark(g); return pop4(g.shape, 1, spv, v); }
    public inline static function get_z(g) { return g.shape[2]; }
    public inline static function set_z(g, v) { mark(g); return pop4(g.shape, 2, spv, v); }

    public inline static function get_s(g) { return g.shape[5]; }
    public inline static function set_s(g, v) { mark(g); return pop4(g.shape, 5, spv, v); }

    public inline static function get_p(g) { return g.shape[6]; }
    public inline static function set_p(g, v) { mark(g); return pop4(g.shape, 6, spv, v); }

    public inline static function set_shape(glyph:Glyph, x, y, z, s, p) {
        set_pos(glyph, x, y, z);
        set_s(glyph, s);
        set_p(glyph, p);
    }

    public inline static function set_pos(glyph:Glyph, x, y, z) {
        set_x(glyph, x);
        set_y(glyph, y);
        set_z(glyph, z);
    }

    public inline static function makeCorners(glyph:Glyph):Void {
        mark(glyph);

        glyph.shape[3 + 0 * spv] = 0; glyph.shape[4 + 0 * spv] = 0;
        glyph.shape[3 + 1 * spv] = 0; glyph.shape[4 + 1 * spv] = 1;
        glyph.shape[3 + 2 * spv] = 1; glyph.shape[4 + 2 * spv] = 1;
        glyph.shape[3 + 3 * spv] = 1; glyph.shape[4 + 3 * spv] = 0;
    }

    // Character

    public inline static function get_char(glyph:Glyph) { return glyph.charCode; }

    public inline static function set_char(glyph:Glyph, code, font:FlatFont) {
        if (get_char(glyph) != code) {
            mark(glyph);
            var charUV = font.getCharCodeUVs(code);
            glyph.color[3 + 0 * cpv] = charUV[3].u; glyph.color[4 + 0 * cpv] = charUV[3].v;
            glyph.color[3 + 1 * cpv] = charUV[0].u; glyph.color[4 + 1 * cpv] = charUV[0].v;
            glyph.color[3 + 2 * cpv] = charUV[1].u; glyph.color[4 + 2 * cpv] = charUV[1].v;
            glyph.color[3 + 3 * cpv] = charUV[2].u; glyph.color[4 + 3 * cpv] = charUV[2].v;
            glyph.charCode = code;
        }
        return code;
    }

    // Paint

    public inline static function get_paint(glyph:Glyph) { return glyph._paint - 1; }

    public inline static function set_paint(glyph:Glyph, val) {
        mark(glyph);

        if (get_paint(glyph) != val) {

            val = val + 1;

            var paintR = ((val >> 16) & 0xFF) / 0xFF;
            var paintG = ((val >>  8) & 0xFF) / 0xFF;
            var paintB = ((val >>  0) & 0xFF) / 0xFF;

            pop4(glyph.paint, 0, ppv, paintR);
            pop4(glyph.paint, 1, ppv, paintG);
            pop4(glyph.paint, 2, ppv, paintB);

            glyph._paint = val;
        }

        return glyph._paint;
    }

    private inline static function pop4<T>(arr:Array<T>, offset, step, val:T):T {
        if (arr[offset + 0 * step] != val) {
            arr[offset + 0 * step] = val;
            arr[offset + 1 * step] = val;
            arr[offset + 2 * step] = val;
            arr[offset + 3 * step] = val;
        }
        return val;
    }

    private inline static function mark(glyph:Glyph) { glyph.dirty = true; }
}
