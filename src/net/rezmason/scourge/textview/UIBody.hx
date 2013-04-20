package net.rezmason.scourge.textview;

import nme.geom.Rectangle;

import net.rezmason.scourge.textview.core.Body;
import net.rezmason.scourge.textview.core.Glyph;

using net.rezmason.scourge.textview.core.GlyphUtils;

class UIBody extends Body {

    inline static var NUM_ROWS:Int = 35;
    inline static var NUM_COLS:Int = 85;

    inline static function inputString():String {
        return [
            'TL                                                                                 TR',
            '                                                                                     ',
            '                                                                                     ',
            '                                                                                     ',
            '                                                                                     ',
            '                                                                                     ',
            '                                                                                     ',
            '                                                                                     ',
            '                                                                                     ',
            '                  ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß                  ',
            '                  ß                                               ß                  ',
            '                  ß  We knew  the world  would not  be the same.  ß                  ',
            '                  ß  Few  people  laughed,  few   people  cried,  ß                  ',
            '                  ß  most people were  silent.  I remembered the  ß                  ',
            '                  ß  line   from   the   Hindu   scripture,  the  ß                  ',
            '                  ß  Bhagavad-Gita. Vishnu is trying to persuade  ß                  ',
            '                  ß  the Prince  that he should do his duty  and  ß                  ',
            '                  ß  to  impress him  takes on  his  multi-armed  ß                  ',
            '                  ß  form  and says,  "Now  I am  become  Death,  ß                  ',
            '                  ß  the destroyer of worlds."  I suppose we all  ß                  ',
            '                  ß  thought that, one way or another.            ß                  ',
            '                  ß                                               ß                  ',
            '                  ß                                               ß                  ',
            '                  ß                          -Robert Oppenheimer  ß                  ',
            '                  ß                                               ß                  ',
            '                  ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß                  ',
            '                                                                                     ',
            '                                                                                     ',
            '                                                                                     ',
            '                                                                                     ',
            '                                                                                     ',
            '                                                                                     ',
            '                                                                                     ',
            '                                                                                     ',
            'BL                                                                                 BR',
        ].join("\n");
    }

    inline static var BOX_SIGIL:String = "ß";

    override function init():Void {

        var strMatrix:Array<Array<String>> = [];
        for (line in inputString().split("\n")) {
            strMatrix.push(line.split(""));
        }

        for (row in 0...NUM_ROWS) {
            for (col in 0...NUM_COLS) {

                var id:Int = row * NUM_COLS + col;

                var glyph:Glyph = new Glyph();
                glyph.visible = true;
                glyph.id = id;
                glyphs.push(glyph);

                var x:Float = ((col + 0.5) / NUM_COLS - 0.5);
                var y:Float = ((row + 0.5) / NUM_ROWS - 0.5);

                var char:String = strMatrix[row][col];
                if (char == BOX_SIGIL) {
                    var left  :Int = (col > 0        && strMatrix[row][col - 1] == BOX_SIGIL) ? 1 : 0;
                    var right :Int = (col <= NUM_COLS && strMatrix[row][col + 1] == BOX_SIGIL) ? 1 : 0;
                    var top   :Int = (row > 0        && strMatrix[row - 1][col] == BOX_SIGIL) ? 1 : 0;
                    var bottom:Int = (row <= NUM_ROWS && strMatrix[row + 1][col] == BOX_SIGIL) ? 1 : 0;

                    var flag:Int = (left << 0) | (right << 1) | (top << 2) | (bottom << 3);
                    char = TestStrings.BOX_SYMBOLS.charAt(flag);
                }

                var charCode:Int = char.charCodeAt(0);

                glyph.makeCorners();
                glyph.set_shape(x, y, 0, 1, 0);
                glyph.set_color(id % 2, 0, (id + 1) % 2, 1);
                glyph.set_char(charCode, glyphTexture.font);
                glyph.set_paint(glyph.id);
            }
        }
    }

    override public function adjustLayout(stageWidth:Int, stageHeight:Int, rect:Rectangle):Void {
        super.adjustLayout(stageWidth, stageHeight, rect);


        glyphTransform.identity();

        var screenSize:Float = Math.sqrt(stageWidth * stageWidth + stageHeight * stageHeight);
        var screenRatio:Float = stageHeight / stageWidth;
        var rectSize:Float = Math.min(rect.width * stageWidth, rect.height * stageHeight) / screenSize;

        var glyphWidth:Float = rectSize * 0.04;

        glyphTransform.appendScale(glyphWidth, glyphWidth * glyphTexture.font.glyphRatio / screenRatio, 1);


        transform.identity();
        transform.appendScale(1, -1, 1);
    }
}
