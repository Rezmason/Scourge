package net.rezmason.scourge.textview;

import nme.geom.Matrix3D;
import nme.geom.Rectangle;
import nme.geom.Vector3D;

using net.rezmason.scourge.textview.core.GlyphUtils;

import net.rezmason.scourge.textview.core.Glyph;
import net.rezmason.scourge.textview.core.Body;

class AlphabetBody extends Body {

    inline static var CHARS:String =
        TestStrings.ALPHANUMERICS +
        TestStrings.SYMBOLS +
        TestStrings.WEIRD_SYMBOLS +
        TestStrings.BOX_SYMBOLS +
    "";

    override function init():Void {

        var totalChars:Int = CHARS.length;
        var numRows:Int = Std.int(Math.ceil(Math.sqrt(totalChars)));
        var numCols:Int = Std.int(Math.ceil(totalChars / numRows));

        for (id in 0...totalChars) {

            var glyph:Glyph = new Glyph();
            glyph.visible = true;
            glyph.id = id;
            glyphs.push(glyph);

            var col:Int = id % numCols;
            var row:Int = Std.int(id / numCols);

            var x:Float = ((col + 0.5) / numCols - 0.5);
            var y:Float = ((row + 0.5) / numRows    - 0.5);

            var charCode:Int = CHARS.charCodeAt(id % CHARS.length);

            glyph.makeCorners();
            glyph.set_shape(x, y, 0, 1, 0);
            glyph.set_color(1, 1, 1);
            glyph.set_i(0.2);
            glyph.set_char(charCode, glyphTexture.font);
            glyph.set_paint(id);
        }
    }

    override public function adjustLayout(stageWidth:Int, stageHeight:Int, rect:Rectangle):Void {
        super.adjustLayout(stageWidth, stageHeight, rect);

        glyphTransform.identity();
        glyphTransform.appendScale(0.05, 0.05 * stageWidth / stageHeight, 1);
    }
}
