package net.rezmason.scourge.textview;

import nme.display.BlendMode;
import nme.display.DisplayObject;
import nme.display.Sprite;
import nme.display.Stage;
import net.rezmason.utils.FlatFont;
import nme.display.BitmapData;
import nme.geom.ColorTransform;
import nme.geom.Matrix;
import nme.geom.Rectangle;

using net.rezmason.scourge.textview.ColorUtils;

class CharSpriteManager {

    var stage:Stage;
    var scene:Sprite;
    var font:FlatFont;
    var fontBD:BitmapData;
    var charRect:Rectangle;
    var defaultMat:Matrix;
    var maxDarkness:Float;

    public function new(stage:Stage, font:FlatFont, maxDarkness:Float):Void {
        this.stage = stage;
        this.font = font;
        this.maxDarkness = maxDarkness;

        scene = new Sprite();
        stage.addChild(scene);

        fontBD = font.getBitmapDataClone();

        charRect = new Rectangle();
        charRect.width  = font.charWidth;
        charRect.height = font.charHeight;

        defaultMat = new Matrix();
    }

    public function createCharSprite(blendMode:BlendMode = null):CharSprite {
        if (blendMode == null) blendMode = BlendMode.ADD;

        var sprite:Sprite = new Sprite();
        scene.addChild(sprite);
        sprite.blendMode = blendMode;

        var billboard:Billboard2D = new Billboard2D(fontBD, defaultMat, charRect);
        billboard.width = Constants.LETTER_WIDTH;
        billboard.height = Constants.LETTER_HEIGHT;
        billboard.x = -billboard.width  * 0.5;
        billboard.y = -billboard.height * 0.5;
        sprite.addChild(billboard);

        /*
        sprite.graphics.beginFill(0xFF0000);
        sprite.graphics.drawCircle(0, 0, 1);
        sprite.graphics.endFill();
        /**/

        return new CharSprite(sprite, billboard);
    }

    public function updateText(charSprite:CharSprite, code:Int, color:Int, inverseVid:Float):Void {
        var mat:Matrix = font.getCharCodeMatrix(code);
        var ct:ColorTransform = new ColorTransform();
        setColorTransform(charSprite.billboard, ct.tint(color, inverseVid));

        charSprite.billboard.update(fontBD, mat, charRect);
    }

    public function updatePosition(charSprite:CharSprite, x:Float, y:Float, z:Float, cx:Float, cy:Float, fl:Float):Void {
        var scale:Float = fl / (fl + z);
        var sprite:Sprite = charSprite.sprite;
        sprite.x = (x - cx) * scale + cx;
        sprite.y = (y - cy) * scale + cy;
        sprite.scaleX = sprite.scaleY = scale;

        var ct:ColorTransform = new ColorTransform();
        var darkness:Float = z / Constants.MAX_DEPTH;
        ct.darken(1 - maxDarkness * darkness);
        setColorTransform(sprite, ct);
    }

    public function updateSwell(charSprite:CharSprite, amount:Float):Void {
        charSprite.sprite.scaleX = amount;
        charSprite.sprite.scaleY = amount;
    }

    function setColorTransform(target:DisplayObject, ct:ColorTransform):Void {
        #if neko target.nmeSetColorTransform(ct);
        #else target.transform.colorTransform = ct;
        #end
    }
}
