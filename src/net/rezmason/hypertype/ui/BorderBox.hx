package net.rezmason.hypertype.ui;

import net.rezmason.math.Vec4;
import net.rezmason.hypertype.Strings.*;
import net.rezmason.hypertype.core.Body;
import net.rezmason.hypertype.core.Glyph;

using net.rezmason.hypertype.core.GlyphUtils;
using net.rezmason.utils.CharCode;

class BorderBox {

    public var body(default, null):Body = new Body();
    public var color(default, set):Vec4 = new Vec4(1, 1, 1);
    public var width(default, set):Float = 0;
    public var height(default, set):Float = 0;
    public var glyphWidth(default, set):Float = 0.1;
    var redrawDeferred = false;
    
    public function new() body.sceneSetSignal.add(redraw);

    public function redraw() {
        if (body.scene == null) return;
        body.glyphScale = glyphWidth * body.scene.camera.rect.width / body.font.glyphRatio;
        var numGlyphsWide = Std.int(Math.ceil(width / glyphWidth));
        var numGlyphsHigh = Std.int(Math.ceil(height / glyphWidth));
        var requiredGlyphs = 4 + 2 * (numGlyphsWide + numGlyphsHigh);
        if (body.size != requiredGlyphs) {
            body.size = requiredGlyphs * 2;
            for (ike in requiredGlyphs...body.size) body.getGlyphByID(ike).reset();
        }
        var stretch = body.font.glyphRatio;
        var top = (height + glyphWidth) / 2;
        var left = -(width + glyphWidth) / 2;
        var itr = 0;
        body.getGlyphByID(itr++).SET({s:1, h:stretch, x: left, y: top, char:    TOP_LEFT.code()});
        body.getGlyphByID(itr++).SET({s:1, h:stretch, x:-left, y: top, char:   TOP_RIGHT.code()});
        body.getGlyphByID(itr++).SET({s:1, h:stretch, x: left, y:-top, char: BOTTOM_LEFT.code()});
        body.getGlyphByID(itr++).SET({s:1, h:stretch, x:-left, y:-top, char:BOTTOM_RIGHT.code()});
        
        var split = 1 - numGlyphsWide % 2;
        var earlyEnd = Std.int(Math.floor(numGlyphsWide / 2)) - split;
        var lateStart = Std.int(Math.ceil(numGlyphsWide / 2)) + split;
        var centerDim = 1 - ((numGlyphsWide - width / glyphWidth) * (1 - 0.5 * split));
        for (ike in 0...numGlyphsWide) {
            var x = -left - (ike + 1 - lateStart) * glyphWidth;
            var h = stretch;
            if (ike < earlyEnd) {
                x = left + (ike + 1) * glyphWidth;
            } else if (ike < lateStart) {
                x = (ike - earlyEnd - 0.5 * split) * glyphWidth * centerDim;
                h = stretch * centerDim;
            }
            body.getGlyphByID(itr++).SET({s:1, h:h, x:x, y: top, char:HORIZONTAL.code()});
            body.getGlyphByID(itr++).SET({s:1, h:h, x:x, y:-top, char:HORIZONTAL.code()});
        }

        split = 1 - numGlyphsHigh % 2;
        earlyEnd = Std.int(Math.floor(numGlyphsHigh / 2)) - split;
        lateStart = Std.int(Math.ceil(numGlyphsHigh / 2)) + split;
        centerDim = 1 - ((numGlyphsHigh - height / glyphWidth) * (1 - 0.5 * split));
        for (ike in 0...numGlyphsHigh) {
            var y = top - (ike + 1 - lateStart) * glyphWidth;
            var s = 1.;
            if (ike < earlyEnd) {
                y = -top + (ike + 1) * glyphWidth;
            } else if (ike < lateStart) {
                y = (ike - earlyEnd - 0.5 * split) * glyphWidth * centerDim;
                s = centerDim;
            }
            body.getGlyphByID(itr++).SET({s:s, h:stretch / s, x: left, y:y, char:VERTICAL.code()});
            body.getGlyphByID(itr++).SET({s:s, h:stretch / s, x:-left, y:y, char:VERTICAL.code()});
        }

        for (ike in 0...requiredGlyphs) body.getGlyphByID(ike).set_color(color);
    }
    
    inline function set_color(color) return this.color = color;
    inline function set_width(width:Float) return this.width = (width < 0 || Math.isNaN(width)) ? 0 : width;
    inline function set_height(height:Float) return this.height = (height < 0 || Math.isNaN(height)) ? 0 : height;
    inline function set_glyphWidth(glyphWidth:Float) return this.glyphWidth = (glyphWidth < 0 || Math.isNaN(glyphWidth)) ? 0 : glyphWidth;
}
