package net.rezmason.scourge.textview.core;

import nme.display.Bitmap;
import nme.display.BitmapData;
import nme.display.Shape;
import nme.display.Sprite;
import nme.text.TextField;


class MouseView extends Sprite {
    public var bitmapData(default, null):BitmapData;
    var bitmap:Bitmap;
    var cursor:Shape;
    var textField:TextField;

    public function new(size:Float):Void {
        super();

        bitmap = new Bitmap();
        bitmap.scaleX = bitmap.scaleY = size;
        cursor = new Shape();
        cursor.graphics.beginFill(0xFF0000);
        cursor.graphics.lineTo(0, 20);
        cursor.graphics.lineTo(10, 16);
        cursor.graphics.endFill();
        textField = new TextField();
        textField.background = true;
        textField.width = textField.height = 40;

        addChild(bitmap);
        addChild(cursor);
        addChild(textField);
    }

    public function configure(width:Int, height:Int):Void {
        if (bitmapData != null) bitmapData.dispose();
        bitmapData = new BitmapData(stage.stageWidth, stage.stageHeight, false, 0x0);
        bitmap.bitmapData = bitmapData;
    }

    public function update(x:Float, y:Float):Void {
        if (bitmapData == null) return;

        cursor.x = x * bitmap.scaleX;
        cursor.y = y * bitmap.scaleY;

        var val:Int = bitmapData.getPixel(Std.int(x), Std.int(y));

        if (val != 0xFFFFFF) {
            cursor.alpha = 1;
            //textField.text = StringTools.hex(val);
            textField.text = Std.string(val);
        } else {
            cursor.alpha = 0.5;
            textField.text = "---";
        }
    }

}
