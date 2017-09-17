package net.rezmason.scourge.pages;

import lime.Assets;
import lime.math.Rectangle;
import lime.math.Vector4;
import net.rezmason.math.Vec4;
import net.rezmason.hypertype.core.Body;
import net.rezmason.hypertype.core.Glyph;
import net.rezmason.hypertype.core.Interaction;
import net.rezmason.hypertype.demo.Demo;

using net.rezmason.hypertype.core.GlyphUtils;

class SplashDemo extends Demo {

    static var SPLASH_COLORS = [
    /*
        'S' => new Vec4(1.00, 0.00, 0.56),
        'C' => new Vec4(1.00, 0.78, 0.00),
        'O' => new Vec4(0.18, 1.00, 0.00),
        'U' => new Vec4(0.00, 0.75, 1.00),
        'R' => new Vec4(1.00, 0.37, 0.00),
        'G' => new Vec4(0.75, 0.00, 1.00),
        'E' => new Vec4(0.18, 0.18, 1.00),
    */
        'M' => new Vec4(1.00, 0.00, 0.56),
        'Y' => new Vec4(1.00, 0.78, 0.00),
        'C' => new Vec4(0.18, 1.00, 0.00),
        'O' => new Vec4(0.00, 0.75, 1.00),
        'T' => new Vec4(1.00, 0.37, 0.00),
        'A' => new Vec4(0.75, 0.00, 1.00),
    ];
    static var WHITE = new Vec4(1, 1, 1);

    var glyphTowers:Array<Array<Glyph>>;
    var lines:Array<String>;

    public function new():Void {
        super();
        lines = Assets.getText('text/splash.txt').split('\n');
        lines.pop();

        var numRows:Int = lines.length;
        var numCols = 0;
        for (line in lines) if (numCols < line.length) numCols = line.length;

        body.size = 3 * numRows * numCols;
        body.glyphScale = 0.015;

        glyphTowers = [];

        var glyphID:Int = 0;
        for (row in 0...numRows) {

            var thickness:Int = 2;

            for (col in 0...numCols) {

                var x:Float = ((col + 0.5) / numCols - 0.5);
                var y:Float = ((row + 0.5) / numRows - 0.5) * 0.3;
                var z:Float = 0.;

                if (lines[row].charAt(col) == ' ') continue;

                var charCode:Int = Std.int(lines[row].charCodeAt(col));
                if (charCode == 0) charCode = -1;

                var color:Vec4 = SPLASH_COLORS[lines[row].charAt(col)];
                var boring = color == null;
                if (boring) color = WHITE;

                var s:Float = 1;
                var a:Float = 0;

                var glyphTower:Array<Glyph> = [];

                for (ike in 0...thickness) {
                    var glyph:Glyph = body.getGlyphByID(glyphID);
                    glyphTower.push(glyph);
                    glyph.set_x(x + (boring ? 0 : (Math.random() - 0.5) * 0.01));
                    glyph.set_y(y + (boring ? 0 : (Math.random() - 0.5) * 0.01));
                    glyph.set_z(z + (boring ? 0 : (Math.random() - 0.5) * 0.01));
                    glyph.SET({a:a, color:color, i:0, char:charCode, hitboxID:glyph.id});
                    z += 0.01;
                    a += boring ? 0.2 : 0.5;
                    color = color * 0.2;
                    glyphID++;
                }

                glyphTowers.push(glyphTower);
            }
        }

        body.transform.appendScale(0.9, 0.9, 0.9);
        body.transform.appendRotation(-40, Vector4.X_AXIS);
        body.glyphScale = 0.022;
    }

    override function update(delta:Float):Void {
        super.update(delta);

        for (ike in 0...glyphTowers.length) {
            var glyphTower:Array<Glyph> = glyphTowers[ike];
            var topGlyph:Glyph = glyphTower[0];

            var d:Float = 1 - ike / glyphTowers.length;
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
