package net.rezmason.scourge.textview;

import net.rezmason.scourge.textview.core.Body;
import net.rezmason.scourge.textview.core.Glyph;

using net.rezmason.scourge.textview.core.GlyphUtils;

class UIBody extends Body {

    inline static var BOX_SIGIL:String = "ß";

    override function makeGlyphs():Void {

        var str:String =
            '                                                                                       \n' +
            '                                                                                       \n' +
            '                                                                                       \n' +
            '                                                                                       \n' +
            '                                                                                       \n' +
            '                                                                                       \n' +
            '                                                                                       \n' +
            '                                                                                       \n' +
            '                                                                                       \n' +
            '                   ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß                   \n' +
            '                   ß                                               ß                   \n' +
            '                   ß  We knew  the world  would not  be the same.  ß                   \n' +
            '                   ß  Few  people  laughed,  few   people  cried,  ß                   \n' +
            '                   ß  most people were  silent.  I remembered the  ß                   \n' +
            '                   ß  line   from   the   Hindu   scripture,  the  ß                   \n' +
            '                   ß  Bhagavad-Gita. Vishnu is trying to persuade  ß                   \n' +
            '                   ß  the Prince  that he should do his duty  and  ß                   \n' +
            '                   ß  to  impress him  takes on  his  multi-armed  ß                   \n' +
            '                   ß  form  and says,  "Now  I am  become  Death,  ß                   \n' +
            '                   ß  the destroyer of worlds."  I suppose we all  ß                   \n' +
            '                   ß  thought that, one way or another.            ß                   \n' +
            '                   ß                                               ß                   \n' +
            '                   ß                                               ß                   \n' +
            '                   ß                          -Robert Oppenheimer  ß                   \n' +
            '                   ß                                               ß                   \n' +
            '                   ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß                   \n' +
            '                                                                                       \n' +
            '                                                                                       \n' +
            '                                                                                       \n' +
            '                                                                                       \n' +
            '                                                                                       \n' +
            '                                                                                       \n' +
            '                                                                                       \n' +
            '                                                                                       \n' +
            '                                                                                       \n' +
            '';

        var strMatrix:Array<Array<String>> = [];
        for (line in str.split("\n")) {
            strMatrix.push(line.split(""));
        }

        super.makeGlyphs();

        var numRows:Int = 35;
        var numCols:Int = 85;
        var totalChars:Int = numCols * numRows;

        for (row in 0...numRows) {
            for (col in 0...numCols) {

                var glyph:Glyph = new Glyph();
                glyph.visible = true;
                glyph.id = row * numCols + col;
                glyphs.push(glyph);

                var x:Float = ((col + 0.5) / numCols - 0.5) * 4 / 3;
                var y:Float = ((row + 0.5) / numRows - 0.5);
                var z:Float = -1;
                z = 0;

                var char:String = strMatrix[row][col];
                if (char == BOX_SIGIL) {
                    var left  :Int = (col > 0        && strMatrix[row][col - 1] == BOX_SIGIL) ? 1 : 0;
                    var right :Int = (col <= numCols && strMatrix[row][col + 1] == BOX_SIGIL) ? 1 : 0;
                    var top   :Int = (row > 0        && strMatrix[row - 1][col] == BOX_SIGIL) ? 1 : 0;
                    var bottom:Int = (row <= numRows && strMatrix[row + 1][col] == BOX_SIGIL) ? 1 : 0;

                    var flag:Int = (left << 0) | (right << 1) | (top << 2) | (bottom << 3);
                    char = TestStrings.BOX_SYMBOLS.charAt(flag);
                }

                var charCode:Int = char.charCodeAt(0);

                var i:Float = 0;
                var s:Float = 0.81;
                var p:Float = 0;

                glyph.makeCorners();
                glyph.set_shape(x, y, z, s, p);
                glyph.set_color(1, 1, 1, i);
                glyph.set_char(charCode, glyphTexture.font);
                glyph.set_paint(glyph.id);
            }
        }
    }
}
