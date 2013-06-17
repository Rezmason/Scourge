package net.rezmason.scourge.textview;

import flash.geom.Rectangle;

import net.rezmason.scourge.textview.core.Glyph;
import net.rezmason.scourge.textview.core.Body;

using net.rezmason.scourge.textview.core.GlyphUtils;

typedef SplashColor = { r:Float, g:Float, b:Float, };

class SplashBody extends Body {

    /*
        {r:1.00, g:0.00, b:0.56}
        {r:1.00, g:0.78, b:0.00}
        {r:0.18, g:1.00, b:0.00}
        {r:0.00, g:0.75, b:1.00}
        {r:1.00, g:0.37, b:0.00}
        {r:0.75, g:0.00, b:1.00}
        {r:0.00, g:0.18, b:1.00}
        {r:0.37, g:0.37, b:0.37}
    */


    static var colors = [
        'S' => {r:1.00, g:0.00, b:0.56},
        'C' => {r:1.00, g:0.78, b:0.00},
        'O' => {r:0.18, g:1.00, b:0.00},
        'U' => {r:0.00, g:0.75, b:1.00},
        'R' => {r:1.00, g:0.37, b:0.00},
        'G' => {r:0.75, g:0.00, b:1.00},
        'E' => {r:0.18, g:0.18, b:1.00},
    ];

    var glyphTowers:Array<Array<Glyph>>;

    var time:Float;

    override function init():Void {

        time = 0;

        var arr:Array<String> = TestStrings.SPLASH.split('\n');
        arr.pop();
        arr.pop();

        var numRows:Int = arr.length;
        var numCols:Int = arr[0].length;

        glyphTowers = [];

        var glyphID:Int = 0;
        for (row in 0...numRows) {

            var thickness:Int = (row == numRows - 1) ? 2 : 3;

            for (col in 0...numCols) {

                var x:Float = ((col + 0.5) / numCols - 0.5) * 2;
                var y:Float = ((row + 0.5) / numRows    - 0.5) * 0.3;
                var z:Float = 0.2;

                if (arr[row].charAt(col) == ' ') continue;

                var charCode:Int = arr[row].charCodeAt(col);

                var color:SplashColor = colors[arr[row].charAt(col)];
                if (color == null) color = {r:1, g:1, b:1};
                var r:Float = color.r;
                var g:Float = color.g;
                var b:Float = color.b;

                var s:Float = 1;

                var glyphTower:Array<Glyph> = [];

                for (ike in 0...thickness) {
                    var glyph:Glyph = new Glyph();
                    glyph.visible = true;
                    glyph.id = glyphID;
                    glyph.prime();
                    glyphs.push(glyph);
                    glyphTower.push(glyph);

                    glyph.set_shape(x, y, z, s, 0);
                    glyph.set_color(r, g, b);
                    glyph.set_i(0);
                    glyph.set_char(charCode, glyphTexture.font);
                    glyph.set_paint(glyph.id | id << 16);
                    glyphID++;

                    z -= 0.03;
                    s *= 1.4;
                    r *= 0.3;
                    g *= 0.3;
                    b *= 0.3;
                }

                glyphTowers.push(glyphTower);
            }
        }
    }

    override public function adjustLayout(stageWidth:Int, stageHeight:Int, rect:Rectangle):Void {
        super.adjustLayout(stageWidth, stageHeight, rect);

        rect = sanitizeLayoutRect(stageWidth, stageHeight, rect);

        var screenSize:Float = Math.sqrt(stageWidth * stageWidth + stageHeight * stageHeight);
        var rectSize:Float = Math.min(rect.width * stageWidth, rect.height * stageHeight) / screenSize;
        var glyphWidth:Float = rectSize * 0.065;
        setGlyphScale(glyphWidth, glyphWidth * glyphTexture.font.glyphRatio * stageWidth / stageHeight);
    }

    //*
    override public function update(delta:Float):Void {
        time += delta;

        for (ike in 0...glyphTowers.length) {
            var glyphTower:Array<Glyph> = glyphTowers[ike];
            var topGlyph:Glyph = glyphTower[0];

            var d:Float = ike / glyphTowers.length;
            var p:Float = (Math.cos(time * 3 + d * 200) * 0.5 + 1) * 0.03 + 0.015;
            var s:Float = (Math.cos(time * 3 + d * 300) * 0.5 + 1) * 0.25 + 0.75;

            //var rgb:RGB = hsv2rgb(hues[ike] + s * 0.1);

            for (glyph in glyphTower) {
                glyph.set_p(p);
                glyph.set_s(s);
                s *= 1.4;
            }

            //glyph.set_color(rgb.r, rgb.g, rgb.b);
        }

        super.update(delta);
    }
    /**/
}
