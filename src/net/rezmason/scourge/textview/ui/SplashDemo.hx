package net.rezmason.scourge.textview.ui;

import flash.geom.Matrix3D;
import flash.geom.Rectangle;
import flash.geom.Vector3D;
import openfl.Assets;

import net.rezmason.scourge.textview.core.Glyph;
import net.rezmason.scourge.textview.core.Body;
import net.rezmason.scourge.textview.core.GlyphTexture;
import net.rezmason.scourge.textview.core.Interaction;

using net.rezmason.scourge.textview.core.GlyphUtils;

class SplashDemo {

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

    static var SPLASH_COLORS = [
        'S' => new Vec3(1.00, 0.00, 0.56),
        'C' => new Vec3(1.00, 0.78, 0.00),
        'O' => new Vec3(0.18, 1.00, 0.00),
        'U' => new Vec3(0.00, 0.75, 1.00),
        'R' => new Vec3(1.00, 0.37, 0.00),
        'G' => new Vec3(0.75, 0.00, 1.00),
        'E' => new Vec3(0.18, 0.18, 1.00),
    ];
    static var WHITE = new Vec3(1, 1, 1);

    public var body(default, null):Body;
    var glyphTowers:Array<Array<Glyph>>;
    var time:Float;
    var lines:Array<String>;

    public function new():Void {
        body = new Body();
        body.updateSignal.add(update);
        time = 0;
        lines = Assets.getText('text/splash.txt').split('\n');
        lines.pop();

        body.growTo(3 * lines.length * lines[0].length);
        body.glyphScale = 0.015;

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

                var color:Vec3 = SPLASH_COLORS[lines[row].charAt(col)];
                if (color == null) color = WHITE;

                var s:Float = 1;

                var glyphTower:Array<Glyph> = [];

                for (ike in 0...thickness) {
                    var glyph:Glyph = body.getGlyphByID(glyphID);
                    glyphTower.push(glyph);
                    glyph.SET({x:x, y:y, z:z, color:color, i:0, char:charCode, paint:glyph.id});
                    z += 0.01;
                    color = color * 0.2;
                    glyphID++;
                }

                glyphTowers.push(glyphTower);
            }
        }

        body.transform.appendScale(1, -1, 1);
        body.transform.appendScale(0.9, 0.9, 0.9);
        body.transform.appendRotation(20, Vector3D.X_AXIS);
    }

    function update(delta:Float):Void {
        time += delta;

        for (ike in 0...glyphTowers.length) {
            var glyphTower:Array<Glyph> = glyphTowers[ike];
            var topGlyph:Glyph = glyphTower[0];

            var d:Float = ike / glyphTowers.length;
            var f:Float = (Math.cos(time * 3 + d * 200) * 0.5 + 1) * 0.3 + 0.25;
            var s:Float = (Math.cos(time * 3 + d * 300) * 0.5 + 1) * 0.3 + 0.5;

            for (glyph in glyphTower) {
                glyph.set_f(f);
                glyph.set_s(s * (glyph.get_z() + 1));
                s *= 2;
            }
        }
    }
}
