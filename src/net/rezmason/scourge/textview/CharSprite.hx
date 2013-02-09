package net.rezmason.scourge.textview;

import nme.display.BlendMode;
import nme.display.DisplayObject;
import nme.display.Sprite;
import nme.display.BitmapData;
import nme.geom.ColorTransform;
import nme.geom.Matrix;
import nme.geom.Rectangle;

using net.rezmason.scourge.textview.ColorUtils;

class CharSprite {

    var sprite:Sprite;
    var billboard:Billboard2D;
    var bd:BitmapData;
    var rect:Rectangle;

    public function new(scene:Sprite, fontBD:BitmapData, mat:Matrix, rect:Rectangle, blendMode:BlendMode = null):Void {

        if (blendMode == null) blendMode = BlendMode.ADD;

        this.rect = rect;
        this.bd = fontBD;

        sprite = new Sprite();
        scene.addChild(sprite);
        sprite.blendMode = blendMode;

        billboard = new Billboard2D(fontBD, mat, rect);
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
    }

    public function updatePosition(x:Float, y:Float, z:Float, cx:Float, cy:Float, fl:Float):Void {
        var scale:Float = fl / (fl + z);
        sprite.x = (x - cx) * scale + cx;
        sprite.y = (y - cy) * scale + cy;
        sprite.scaleX = sprite.scaleY = scale;

        var ct:ColorTransform = new ColorTransform();
        ct.darken(1 - z / Constants.MAX_DEPTH);
        setColorTransform(sprite, ct);
    }

    public function updateText(mat:Matrix, color:Int, inverseVid:Float):Void {
        var ct:ColorTransform = new ColorTransform();
        setColorTransform(billboard, ct.tint(color, inverseVid));

        billboard.update(bd, mat, rect);
    }

    public function updateSwell(amount:Float):Void {
        sprite.scaleX = amount;
        sprite.scaleY = amount;
    }

    function setColorTransform(target:DisplayObject, ct:ColorTransform):Void {
        #if neko target.nmeSetColorTransform(ct);
        #else target.transform.colorTransform = ct;
        #end
    }

}
