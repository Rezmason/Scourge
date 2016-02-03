package net.rezmason.scourge.pages;

import lime.Assets;
import lime.math.Rectangle;
import lime.math.Vector4;
import net.rezmason.math.Vec3;
import net.rezmason.hypertype.core.Body;
import net.rezmason.hypertype.core.Glyph;
import net.rezmason.hypertype.core.Interaction;
import net.rezmason.hypertype.demo.Demo;

using net.rezmason.hypertype.core.GlyphUtils;

class SplashDemo extends Demo {

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

    var glyphTowers:Array<Array<Glyph>>;
    var lines:Array<String>;

    public function new():Void {
        super();
        lines = Assets.getText('text/splash.txt').split('\n');
        lines.pop();

        body.growTo(3 * lines.length * lines[0].length);
        body.glyphScale = 0.015;

        var numRows:Int = lines.length;
        var numCols:Int = lines[0].length;

        glyphTowers = [];

        var glyphID:Int = 0;
        for (row in 0...numRows) {

            var thickness:Int = 2;

            for (col in 0...numCols) {

                var x:Float = ((col + 0.5) / numCols - 0.5);
                var y:Float = ((row + 0.5) / numRows - 0.5) * 0.15;
                var z:Float = 0.;

                if (lines[row].charAt(col) == ' ') continue;

                var charCode:Int = lines[row].charCodeAt(col);

                var color:Vec3 = SPLASH_COLORS[lines[row].charAt(col)];
                if (color == null) color = WHITE;

                var s:Float = 1;
                var a:Float = 0;

                var glyphTower:Array<Glyph> = [];

                for (ike in 0...thickness) {
                    var glyph:Glyph = body.getGlyphByID(glyphID);
                    glyphTower.push(glyph);
                    glyph.SET({x:x, y:y, z:z, a:a, color:color, i:0, char:charCode, hitboxID:glyph.id});
                    z += 0.01;
                    a += 0.5;
                    color = color * 0.2;
                    glyphID++;
                }

                glyphTowers.push(glyphTower);
            }
        }

        body.transform.appendScale(1, -1, 1);
        body.transform.appendScale(0.9, 0.9, 0.9);
        body.transform.appendRotation(20, Vector4.X_AXIS);
    }

    override function update(delta:Float):Void {
        super.update(delta);

        for (ike in 0...glyphTowers.length) {
            var glyphTower:Array<Glyph> = glyphTowers[ike];
            var topGlyph:Glyph = glyphTower[0];

            var d:Float = ike / glyphTowers.length;
            var w:Float = (Math.cos(time * 3 + d * 200) * 0.5 + 1) * 0.3 - 0.25;
            var s:Float = (Math.cos(time * 3 + d * 300) * 0.5 + 1) * 0.3 + 0.5;

            for (glyph in glyphTower) {
                glyph.set_w(w);
                glyph.set_s(s * (2 * glyph.get_z() + 1));
                s *= 2;
            }
        }
    }
}
