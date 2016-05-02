package net.rezmason.hypertype.ui;

import haxe.Utf8;
import net.rezmason.math.Vec4;
import net.rezmason.hypertype.text.ParagraphAlign;

using net.rezmason.hypertype.core.GlyphUtils;
using net.rezmason.utils.CharCode;

class TextLabel extends TextObject {

    static var LINE_END = ~/[\n\r]/g;
    var lines:Array<String>;
    
    override function processText() {
        if (text == null) {
            lines = [];
            numRequiredGlyphs = 0;
        } else {
            lines = LINE_END.split(text);
            numRequiredGlyphs = text.length - (lines.length - 1);
        }
    }

    override function updateGlyphs() {
        var glyphIndex = 0;
        var xOffset =  glyphWidth  / 2;
        var yOffset = -glyphHeight / 2;

        var startY:Float = 0;
        switch (verticalAlign) {
            case MIDDLE: startY = lines.length * glyphHeight / 2;
            case BOTTOM: startY = lines.length * glyphHeight;
            case _:
        }

        for (ike in 0...lines.length) {
            var line = lines[ike];
            var startX:Float = 0;
            switch (align) {
                case CENTER: startX = -line.length * glyphWidth / 2;
                case RIGHT: startX = -line.length * glyphWidth;
                case _:
            }
            for (jen in 0...line.length) {
                body.getGlyphByID(glyphIndex).SET({
                    x: startX + xOffset + jen * glyphWidth, 
                    y: startY + yOffset - ike * glyphHeight, 
                    char:line.charCodeAt(jen),
                    color:color,
                });
                glyphIndex++;
            }
        }
    }
}
