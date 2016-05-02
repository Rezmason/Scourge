package net.rezmason.hypertype.ui;

import haxe.Utf8;
import net.rezmason.math.Vec4;
import net.rezmason.hypertype.Strings.*;
import net.rezmason.hypertype.core.Body;
import net.rezmason.hypertype.core.Glyph;
import net.rezmason.hypertype.text.ParagraphAlign; // TODO: move to UI

using net.rezmason.hypertype.core.GlyphUtils;
using net.rezmason.utils.CharCode;

class TextBox extends TextObject {

    public var width(default, set):Float = 0;
    public var height(default, set):Float = 0;

    var numGlyphsWide:UInt;
    var numGlyphsHigh:UInt;
    
    override function processText() {
        numGlyphsWide = Std.int(Math.ceil(width / glyphWidth));
        numGlyphsHigh = Std.int(Math.ceil(height / glyphWidth));
        numRequiredGlyphs = (numGlyphsWide + 2) * numGlyphsHigh + 2;

        var spanSets = [for (passage in text.split('\n')) passage.split(' ')]; 

        // At this point the number of lines is known, and each line has a character budget
        // Assign successive NonBreakingSpans to a Line while the span length is less than the remainder of the budget
        // Spans longer than the character budget must be broken
        // A Line 'terminatesEarly' unless it is the last Line for a given Array<NonbreakingSpan>

        // Now we have distinct Lines
        // Left, right, and centered lines have constant (standard) glyph width, resizing edge spacers
        // A justified Line that 'terminatesEarly' use its secondary align behavior
        // Otherwise a justified Line has zero-size left and right spacers, and variable width spaces
        // For now, the width for every space is the remaining budget divided by the number of spaces
        // TODO: enforceMonospace
        
        // Now we have an Array<Array<Glyph>>
        // Position each glyph from left to right
        // TODO: verticalAlign
        // Size and position top spacer and bottom spacer
    }
    
    inline function set_width(width:Float) return this.width = (width < 0 || Math.isNaN(width)) ? 0 : width;
    inline function set_height(height:Float) return this.height = (height < 0 || Math.isNaN(height)) ? 0 : height;
}
