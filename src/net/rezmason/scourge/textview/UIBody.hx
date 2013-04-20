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
            '                ßßß¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬ßßß                ',
            '                ß ß¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬ß ß                ',
            '                ßß                                                 ßß                ',
            '                ¬¬                                                 ¬¬                ',
            '                ¬¬   We knew  the world  would not  be the same.   ¬¬                ',
            '                ¬¬   Few  people  laughed,  few   people  cried,   ¬¬                ',
            '                ¬¬   most people were  silent.  I remembered the   ¬¬                ',
            '                ¬¬   line   from   the   Hindu   scripture,  the   ¬¬                ',
            '                ¬¬   Bhagavad-Gita. Vishnu is trying to persuade   ¬¬                ',
            '                ¬¬   the Prince  that he should do his duty  and   ¬¬                ',
            '                ¬¬   to  impress him  takes on  his  multi-armed   ¬¬                ',
            '                ¬¬   form  and says,  "Now  I am  become  Death,   ¬¬                ',
            '                ¬¬   the destroyer of worlds."  I suppose we all   ¬¬                ',
            '                ¬¬   thought that, one way or another.             ¬¬                ',
            '                ¬¬                                                 ¬¬                ',
            '                ¬¬                                                 ¬¬                ',
            '                ¬¬                           -Robert Oppenheimer   ¬¬                ',
            '                ¬¬                                                 ¬¬                ',
            '                ßß                                                 ßß                ',
            '                ß ß¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬ß ß                ',
            '                ßßß¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬ßßß                ',
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
    inline static var LINE_SIGIL:String = "¬";

    override function init():Void {

        var sigils:EReg = ~/[ß¬]/;

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

                /*
                var char:String = strMatrix[row][col];
                if (sigils.match(char)) {
                    var left  :Int = (col > 0            && sigils.match(strMatrix[row][col - 1])) ? 1 : 0;
                    var right :Int = (col < NUM_COLS - 1 && sigils.match(strMatrix[row][col + 1])) ? 1 : 0;
                    var top   :Int = (row > 0            && sigils.match(strMatrix[row - 1][col])) ? 1 : 0;
                    var bottom:Int = (row < NUM_ROWS - 1 && sigils.match(strMatrix[row + 1][col])) ? 1 : 0;

                    if (char == LINE_SIGIL) {
                        if (left & right == 1) top = bottom = 0;
                        if (top & bottom == 1) left = right = 0;
                    }

                    var flag:Int = (left << 0) | (right << 1) | (top << 2) | (bottom << 3);
                    char = TestStrings.BOX_SYMBOLS.charAt(flag);
                }

                var charCode:Int = char.charCodeAt(0);
                */

                var charCode:Int = (id % 26) + 65;

                glyph.makeCorners();
                glyph.set_shape(x, y, 0, 1, 0);
                glyph.set_color(id % 2, 0, (id + 1) % 2, 1);
                //glyph.set_color(1, 1, 1, 0);
                glyph.set_char(charCode, glyphTexture.font);
                glyph.set_paint(glyph.id);
            }
        }
    }

    override public function adjustLayout(stageWidth:Int, stageHeight:Int, rect:Rectangle):Void {
        super.adjustLayout(stageWidth, stageHeight, rect);

        var screenRatio:Float = stageHeight / stageWidth;
        glyphTransform.identity();
        var glyphWidth:Float = rect.width / NUM_COLS;
        var glyphHeight:Float = rect.height / NUM_ROWS;

        glyphTransform.appendScale(glyphWidth * 2, glyphHeight * 2, 1);

        transform.identity();
        transform.appendScale(1, -1, 1);
    }
}
