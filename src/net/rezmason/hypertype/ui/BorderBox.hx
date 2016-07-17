package net.rezmason.hypertype.ui;

import net.rezmason.math.Vec4;
import net.rezmason.hypertype.Strings.*;
import net.rezmason.hypertype.core.Body;
import net.rezmason.hypertype.core.Glyph;

using net.rezmason.hypertype.core.GlyphUtils;
using net.rezmason.utils.CharCode;

class BorderBox {

    inline static var MIN_GLYPH_WIDTH = 0.001;
    public var body(default, null):Body = new Body();
    public var width(default, set):Float = 0;
    public var height(default, set):Float = 0;
    public var glyphWidth(default, set):Float = 0.1;
    public var rounded:Bool;
    public var color:Vec4 = new Vec4(1, 1, 1);

    public function new() {}
    
    public function redraw() {
        var displayedGlyphWidth = glyphWidth;
        if (displayedGlyphWidth > width  && width  > 0) displayedGlyphWidth = width;
        if (displayedGlyphWidth > height && height > 0) displayedGlyphWidth = height;

        body.glyphScale = displayedGlyphWidth / body.font.glyphRatio;

        var displayedWidth  = Math.max(0, width   - displayedGlyphWidth);
        var displayedHeight = Math.max(0, height  - displayedGlyphWidth);

        var numGlyphsWide = Std.int(Math.ceil(displayedWidth  / displayedGlyphWidth));
        var numGlyphsHigh = Std.int(Math.ceil(displayedHeight / displayedGlyphWidth));

        if (displayedWidth * displayedHeight == 0 || displayedGlyphWidth < MIN_GLYPH_WIDTH) {
            for (ike in 0...body.size) body.getGlyphByID(ike).reset();
            body.size = 0;
            return;
        }

        var requiredGlyphs = 4 + 2 * (numGlyphsWide + numGlyphsHigh);
        if (body.size != requiredGlyphs) {
            body.size = requiredGlyphs * 2;
            for (ike in requiredGlyphs...body.size) body.getGlyphByID(ike).reset();
        }

        var stretch = body.font.glyphRatio;
        var itr = 0;

        body.getGlyphByID(itr++).SET({s:1, h:stretch, x:    0, y:      0, char:rounded ?     ROUNDED_TOP_LEFT.code() :     SHARP_TOP_LEFT.code()});
        body.getGlyphByID(itr++).SET({s:1, h:stretch, x:width, y:      0, char:rounded ?    ROUNDED_TOP_RIGHT.code() :    SHARP_TOP_RIGHT.code()});
        body.getGlyphByID(itr++).SET({s:1, h:stretch, x:    0, y: height, char:rounded ?  ROUNDED_BOTTOM_LEFT.code() :  SHARP_BOTTOM_LEFT.code()});
        body.getGlyphByID(itr++).SET({s:1, h:stretch, x:width, y: height, char:rounded ? ROUNDED_BOTTOM_RIGHT.code() : SHARP_BOTTOM_RIGHT.code()});

        var split = 1 - numGlyphsWide % 2;
        var earlyEnd = Std.int(Math.floor(numGlyphsWide * 0.5)) - split;
        var lateStart = Std.int(Math.ceil(numGlyphsWide * 0.5)) + split;
        var centerDim = 1 - ((numGlyphsWide - displayedWidth / displayedGlyphWidth) * (1 - 0.5 * split));
        for (ike in 0...numGlyphsWide) {
            var x = width - (ike + 1 - lateStart) * displayedGlyphWidth;
            var h = stretch;
            if (ike < earlyEnd) {
                x = (ike + 1) * displayedGlyphWidth;
            } else if (ike < lateStart) {
                x = width * 0.5 + (ike - earlyEnd - 0.5 * split) * displayedGlyphWidth * centerDim;
                h = stretch * centerDim;
            }
            var s = 1.;
            body.getGlyphByID(itr++).SET({s:s, h:h, x: x, y:      0, char:HORIZONTAL.code()});
            body.getGlyphByID(itr++).SET({s:s, h:h, x: x, y: height, char:HORIZONTAL.code()});
        }

        split = 1 - numGlyphsHigh % 2;
        earlyEnd = Std.int(Math.floor(numGlyphsHigh * 0.5)) - split;
        lateStart = Std.int(Math.ceil(numGlyphsHigh * 0.5)) + split;
        centerDim = 1 - ((numGlyphsHigh - displayedHeight / displayedGlyphWidth) * (1 - 0.5 * split));
        for (ike in 0...numGlyphsHigh) {
            var y = height - (ike + 1 - lateStart) * displayedGlyphWidth;
            var s = 1.;
            if (ike < earlyEnd) {
                y = (ike + 1) * displayedGlyphWidth;
            } else if (ike < lateStart) {
                y = height * 0.5 + (ike - earlyEnd - 0.5 * split) * displayedGlyphWidth * centerDim;
                s = centerDim;
            }
            var h = stretch / s;

            body.getGlyphByID(itr++).SET({s:s, h:h, x: 0,     y: y, char:VERTICAL.code()});
            body.getGlyphByID(itr++).SET({s:s, h:h, x: width, y: y, char:VERTICAL.code()});
        }

        for (ike in 0...requiredGlyphs) body.getGlyphByID(ike).set_color(color);
    }
    
    inline function set_width(width:Float) return this.width = (width < 0 || Math.isNaN(width)) ? 0 : width;
    inline function set_height(height:Float) return this.height = (height < 0 || Math.isNaN(height)) ? 0 : height;
    inline function set_glyphWidth(glyphWidth:Float) return this.glyphWidth = (glyphWidth < 0 || Math.isNaN(glyphWidth)) ? 0 : glyphWidth;
}
