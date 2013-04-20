package net.rezmason.scourge.textview;

import com.adobe.utils.PerspectiveMatrix3D;
import nme.geom.Matrix3D;
import nme.geom.Rectangle;
import nme.geom.Vector3D;

import net.rezmason.utils.FatChar;
import net.rezmason.scourge.textview.core.Glyph;
import net.rezmason.scourge.textview.core.Body;

using net.rezmason.scourge.textview.core.GlyphUtils;

class TestBody extends Body {

    var projection:PerspectiveMatrix3D;

    inline static var COLOR_RANGE:Int = 6;
    inline static var CHARS:String =
        TestStrings.ALPHANUMERICS +
    "";

    override function init():Void {

        projection = new PerspectiveMatrix3D();
        projection.perspectiveLH(2, 2, 1, 2);

        var numCols:Int = 30;
        var numRows:Int = 30;
        var totalChars:Int = numCols * numRows;

        for (ike in 0...totalChars) {

            var glyph:Glyph = new Glyph();
            glyph.visible = true;
            glyph.id = ike;
            glyphs.push(glyph);

            var col:Int = ike % numCols;
            var row:Int = Std.int(ike / numCols);

            var x:Float = (col + 0.5) / numCols - 0.5;
            var y:Float = (row + 0.5) / numRows - 0.5;
            var z:Float = -0.5;

            z *= Math.cos(row / numRows * Math.PI * 2);
            z *= Math.cos(col / numCols * Math.PI * 2);

            var r:Float = Std.random(COLOR_RANGE) / (COLOR_RANGE - 1);
            var g:Float = Std.random(COLOR_RANGE) / (COLOR_RANGE - 1);
            var b:Float = Std.random(COLOR_RANGE) / (COLOR_RANGE - 1);

            //*
            r = row / numRows;
            g = col / numCols;
            b = Math.cos(r) * Math.cos(g) * 0.5;
            /**/

            r *= 0.6;
            g *= 0.6;
            b *= 0.6;

            var i:Float = 0.2;
            var s:Float = 2;
            var p:Float = 0;

            var charCode:Int = CHARS.charCodeAt(ike % CHARS.length);

            glyph.makeCorners();
            glyph.set_shape(x, y, z, s, p);
            glyph.set_color(r, g, b, i);
            glyph.set_char(charCode, glyphTexture.font);
            glyph.set_paint(ike);
        }
    }

    override public function adjustLayout(stageWidth:Int, stageHeight:Int, rect:Rectangle):Void {
        super.adjustLayout(stageWidth, stageHeight, rect);

        glyphTransform.identity();

        var screenSize:Float = Math.sqrt(stageWidth * stageWidth + stageHeight * stageHeight);
        var screenRatio:Float = stageHeight / stageWidth;
        var rectSize:Float = Math.min(rect.width * stageWidth, rect.height * stageHeight) / screenSize;

        var glyphWidth:Float = rectSize * 0.03;

        glyphTransform.appendScale(glyphWidth, glyphWidth * glyphTexture.font.glyphRatio / screenRatio, 1);

        var letterbox:Matrix3D = new Matrix3D();
        var boxRatio:Float = (rect.width / rect.height) / screenRatio;
        if (boxRatio < 1) letterbox.appendScale(1, boxRatio, 1);
        else letterbox.appendScale(1 / boxRatio, 1, 1);
        camera.prepend(letterbox);

        camera.appendTranslation(0, 0, 1);

        rect = rect.clone();
        rect.offset(-0.5, -0.5);
        rect.x *= 2;
        rect.y *= 2;
        rect.width *= 2;
        rect.height *= 2;

        camera.append(projection);

        var vec:Vector3D = new Vector3D();
        camera.copyColumnTo(2, vec);
        vec.x += (rect.left + rect.right) *  0.5;
        vec.y += (rect.top + rect.bottom) * -0.5;
        camera.copyColumnFrom(2, vec);
    }
}
