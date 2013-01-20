package net.rezmason.scourge.view;

import nme.Assets;
import nme.display.Bitmap;
import nme.display.BitmapData;
import nme.display.BlendMode;
import nme.display.Sprite;
import nme.geom.ColorTransform;
import nme.geom.Matrix;
import nme.text.AntiAliasType;
import nme.text.TextField;
import nme.text.TextFieldAutoSize;
import nme.text.TextFormat;

using Lambda;

class FontBlitThing {

    public function new(scene:Sprite, message:String, colors:Hash<Int>):Void {

        var requiredChars:Array<String> = [];

        for (ike in 0...message.length) {
            var char = message.charAt(ike);
            if (char != "\n" && !requiredChars.has(char)) requiredChars.push(char);
        }

        var font = Assets.getFont("assets/ProFontX.ttf");
        var format = new TextFormat(font.fontName, 14, 0x0);

        var textField = new TextField();
        textField.antiAliasType = AntiAliasType.ADVANCED;
        #if flash textField.thickness = 100; #end
        //textField.sharpness = -400;
        textField.defaultTextFormat = format;
        textField.selectable = false;
        textField.embedFonts = true;
        textField.width = 5;
        textField.height = 5;
        textField.x = 0;
        textField.y = 0;
        textField.autoSize = TextFieldAutoSize.LEFT;

        var mag:Int = 2;
        textField.text = "{";
        var bounds = textField.getBounds(textField);

        bounds.top = Math.floor(bounds.top);
        bounds.bottom = Math.ceil(bounds.bottom);
        bounds.left = Math.floor(bounds.left);
        bounds.right = Math.ceil(bounds.right);

        bounds.right -= 2;

        var wid:Int = Std.int(bounds.width ) * mag;
        var hgt:Int = Std.int(bounds.height) * mag;

        var charBitmaps:Hash<BitmapData> = new Hash<BitmapData>();
        for (char in requiredChars) {
            textField.text = char;
            var bd = new BitmapData(wid, hgt, true, 0x01000000);
            var mat = new Matrix();
            mat.tx = bounds.left;
            mat.ty = bounds.top;
            mat.scale(mag, mag);
            //bd.noise(0);
            bd.draw(textField, mat);
            charBitmaps.set(char, bd);

            if (~/\s+/g.match(char)) bd.fillRect(bd.rect, 0x0);
        }

        /*
        var x:Float = 0;
        for (bd in charBitmaps) {
            var bmp = new Bitmap(bd);
            bmp.smoothing = true;
            bmp.scaleX = bmp.scaleY = 1 / mag;
            bmp.y = 300;
            bmp.x = x;
            x += bmp.width;
            scene.addChild(bmp);
        }
        */

        var ct:ColorTransform = new ColorTransform();

        var container = new Sprite();

        var charSymbols = [];

        for (y in 0...Std.int(scene.stage.stageHeight / bounds.height)) {
            charSymbols[y] = [];
            for (x in 0...Std.int(scene.stage.stageWidth / bounds.width)) {
                //var rand:Int = Std.random(message.length);
                //var char:String = message.charAt(rand);
                var char:String = " ";

                var bd = charBitmaps.get(char);
                tint(ct, colors.get(char), y / 20);

                var bmp = new Bitmap(bd);
                bmp.smoothing = true;
                bmp.scaleX = bmp.scaleY = 1 / mag;
                bmp.x = -bmp.width / 2;
                bmp.y = -bmp.height / 2;
                bmp.transform.colorTransform = ct;
                bmp.blendMode = BlendMode.ADD;

                var sprite = new Sprite();
                /*
                sprite.graphics.beginFill(0xFF0000);
                sprite.graphics.drawCircle(0, 0, 1);
                sprite.graphics.endFill();
                */

                sprite.addChild(bmp);
                sprite.x = x * bounds.width  + sprite.width / 2;
                sprite.y = y * bounds.height + sprite.height / 2;

                var rand:Float = Math.random() * 0.7 + 0.3;
                sprite.scaleX = sprite.scaleY = rand + 1;
                sprite.alpha = 1 - 0.5 * rand;
                container.addChild(sprite);

                charSymbols[y][x] = bmp;
            }
        }

        scene.addChild(container);
        container.x = (scene.stage.stageWidth  - container.width ) / 2;
        container.y = (scene.stage.stageHeight - container.height) / 2;

        var x = 0;
        var y = 0;
        for (ike in 0...message.length) {
            var char = message.charAt(ike);
            if (char == "\n" || charSymbols[y][x] == null) {
                x = 0;
                y++;
                if (y > charSymbols.length) break;
            }
            if (char == "\n") continue;

            tint(ct, colors.get(char), 0);
            var bmp = charSymbols[y][x];
            bmp.transform.colorTransform = ct;
            bmp.bitmapData = charBitmaps.get(char);
            bmp.smoothing = true;

            x++;
        }
    }

    private function tint(ct:ColorTransform, color:Null<Int>, brightness:Float = 0):Void {
        if (color == null) color = 0xFFFFFF;
        ct.color = color;

        if (brightness < 0) brightness = 0;
        else if (brightness > 1) brightness = 1;

        ct.alphaOffset = Std.int(0xFF * brightness);

        if (brightness > 0.8) ct.alphaMultiplier = 1 - 2 * brightness;
        else ct.alphaMultiplier = 1;
    }

    private function colorize(str:String, color:Int):String {
        return "<FONT COLOR='#" + StringTools.hex(color) + "'>" + str + "</FONT>";
    }
}
