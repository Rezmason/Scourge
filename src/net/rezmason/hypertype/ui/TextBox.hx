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

    public var width(default, set):Float = 10;
    public var height(default, set):Float = 10;

    var numGlyphsWide:UInt;
    var numGlyphsHigh:UInt;
    var lines:Array<String>;
    var earlyTerminatingLines:Array<UInt>;
    
    override function processText() {
        numGlyphsWide = Std.int(width / glyphWidth);

        var wordSequences = [for (passage in text.split('\n')) passage.split(' ')];
        lines = [];
        earlyTerminatingLines = [];
        var currentLine = '';
        for (sequence in wordSequences) {
            var space = '';
            for (originalWord in sequence) {
                if (currentLine.length + space.length + originalWord.length <= numGlyphsWide) {
                    currentLine += space + originalWord;
                } else {
                    space = '';
                    var word = originalWord;
                    while (word.length > 0) {
                        lines.push(currentLine);
                        currentLine = word.substr(0, numGlyphsWide);
                        word = word.substr(numGlyphsWide);
                    }
                }
                space = ' ';
            }
            earlyTerminatingLines.push(lines.length);
            lines.push(currentLine);
            currentLine = '';
        }
        if (currentLine.length > 0) lines.push(currentLine);
        
        numGlyphsHigh = Std.int(height / glyphHeight);
        if (numGlyphsHigh > lines.length) numGlyphsHigh = lines.length;
        numRequiredGlyphs = 0;
        for (ike in 0...numGlyphsHigh) numRequiredGlyphs += lines[ike].length;
    }

    override function updateGlyphs() {
        var startY:Float = 0;
        switch (verticalAlign) {
            case MIDDLE: startY = (-height + numGlyphsHigh * glyphHeight) / 2;
            case BOTTOM: startY = -height + numGlyphsHigh * glyphHeight;
            case _:
        }
        startY += glyphHeight / 2;

        var glyphIndex = 0;
        var y = startY;
        for (ike in 0...numGlyphsHigh) {
            var line = lines[ike];
            var terminatesEarly = earlyTerminatingLines.indexOf(ike) != -1;
            var startX:Float = 0;
            var spaceWidth = 1.0;
            switch (align) {
                case LEFT: startX = 0;
                case JUSTIFY(LEFT) if (terminatesEarly): startX = 0;
                case CENTER: startX = (width - line.length * glyphWidth )/ 2;
                case JUSTIFY(CENTER) if (terminatesEarly): startX = (width - line.length * glyphWidth )/ 2;
                case RIGHT: startX = width - line.length * glyphWidth;
                case JUSTIFY(RIGHT) if (terminatesEarly): startX = width - line.length * glyphWidth;
                case JUSTIFY(_):
                    var numSpaces = line.split(' ').length - 1;
                    var diff = width / glyphWidth - line.length;
                    spaceWidth = 1 + diff / numSpaces;
            }
            startX += glyphWidth  / 2;

            var x = startX;
            for (jen in 0...line.length) {
                var charCode = line.charCodeAt(jen);
                var glyph = body.getGlyphByID(glyphIndex);
                glyph.COPY(style, [r, g, b, i, a, w, hitboxID, hitboxS, hitboxH]);
                glyph.SET({x: x, y: y, char:charCode});
                if (charCode == 32) x += spaceWidth * glyphWidth;
                else x += glyphWidth;
                glyphIndex++;
            }
            y += glyphHeight;
        }
    }
    
    inline function set_width(width:Float) return this.width = (width < 0 || Math.isNaN(width)) ? 0 : width;
    inline function set_height(height:Float) return this.height = (height < 0 || Math.isNaN(height)) ? 0 : height;
}
