package net.rezmason.scourge.textview;

import flash.geom.Matrix3D;
import flash.geom.Rectangle;
import flash.geom.Vector3D;

import net.rezmason.gl.utils.BufferUtil;

import net.rezmason.scourge.textview.core.Glyph;
import net.rezmason.scourge.textview.core.Body;
import net.rezmason.scourge.textview.core.BodyScaleMode;
import net.rezmason.scourge.textview.core.GlyphTexture;
import net.rezmason.scourge.textview.core.Interaction;

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

    var baseCamera:Matrix3D;

    var time:Float;
    var lines:Array<String>;

    public function new(bufferUtil:BufferUtil, glyphTexture:GlyphTexture, redrawHitAreas:Void->Void):Void {

        super(bufferUtil, glyphTexture, redrawHitAreas);

        baseCamera = new Matrix3D();

        scaleMode = WIDTH_FIT;

        time = 0;

        lines = Strings.SPLASH.split('\n');
        lines.pop();
        lines.pop();

        growTo(3 * lines.length * lines[0].length);

        var numRows:Int = lines.length;
        var numCols:Int = lines[0].length;

        glyphTowers = [];

        var glyphID:Int = 0;
        for (row in 0...numRows) {

            var thickness:Int = (row == numRows - 1) ? 2 : 3;

            for (col in 0...numCols) {

                var x:Float = ((col + 0.5) / numCols - 0.5);
                var y:Float = ((row + 0.5) / numRows - 0.5) * 0.15;
                var z:Float = 0.;

                if (lines[row].charAt(col) == ' ') continue;

                var charCode:Int = lines[row].charCodeAt(col);

                var color:SplashColor = colors[lines[row].charAt(col)];
                if (color == null) color = {r:1, g:1, b:1};
                var r:Float = color.r;
                var g:Float = color.g;
                var b:Float = color.b;

                var s:Float = 1;

                var glyphTower:Array<Glyph> = [];

                for (ike in 0...thickness) {
                    var glyph:Glyph = glyphs[glyphID];

                    glyphTower.push(glyph);

                    glyph.set_shape(x, y, z, 1, 0);
                    glyph.set_color(r, g, b);
                    glyph.set_i(0);
                    glyph.set_char(charCode, glyphTexture.font);
                    glyph.set_paint(glyph.id | id << 16);

                    z += 0.01;
                    r *= 0.2;
                    g *= 0.2;
                    b *= 0.2;

                    glyphID++;
                }

                glyphTowers.push(glyphTower);
            }
        }

        transform.appendScale(1, -1, 1);
        transform.appendScale(0.9, 0.9, 0.9);
        transform.appendRotation(20, Vector3D.X_AXIS);
    }

    override public function adjustLayout(stageWidth:Int, stageHeight:Int):Void {
        super.adjustLayout(stageWidth, stageHeight);

        // baseCamera.copyFrom(camera);

        var rect:Rectangle = sanitizeLayoutRect(stageWidth, stageHeight, viewRect);
        var glyphWidth:Float = rect.width * 0.03;

        setGlyphScale(glyphWidth, glyphWidth * glyphTexture.font.glyphRatio * stageWidth / stageHeight);
    }

    /*
    override public function interact(id:Int, interaction:Interaction):Void {
        var glyph:Glyph = glyphs[id];
        switch (interaction) {
            case MOUSE(MOVE, x, y):
                applyVP(x - 0.5, y - 0.5);
            case _:
        }
    }
    */

    //*
    override public function update(delta:Float):Void {
        time += delta;

        for (ike in 0...glyphTowers.length) {
            var glyphTower:Array<Glyph> = glyphTowers[ike];
            var topGlyph:Glyph = glyphTower[0];

            var d:Float = ike / glyphTowers.length;
            var p:Float = (Math.cos(time * 3 + d * 200) * 0.5 + 1) * 0.001;
            var f:Float = (Math.cos(time * 3 + d * 200) * 0.5 + 1) * 0.4 + 0.1;
            var s:Float = (Math.cos(time * 3 + d * 300) * 0.5 + 1) * 0.1 + 0.9;

            //var rgb:RGB = hsv2rgb(hues[ike] + s * 0.1);

            for (glyph in glyphTower) {
                glyph.set_p(p);
                glyph.set_f(f);
                glyph.set_s(s * (glyph.get_z() + 1));
                s *= 2;
            }

            //glyph.set_color(rgb.r, rgb.g, rgb.b);
        }

        // transform.appendRotation(1, Vector3D.X_AXIS);

        super.update(delta);
    }
    /**/
}
