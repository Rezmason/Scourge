package net.rezmason.scourge.textview;

import nme.display.BitmapData;
import nme.display.Bitmap;
import nme.display.BlendMode;
import nme.display.Sprite;
import nme.geom.Rectangle;

import net.rezmason.utils.FlatFont;

class TextBlitter {

    var chars:Array<Array<String>>;
    var colors:Hash<Int>;
    var fontBD:BitmapData;
    var flatFont:FlatFont;
    var charDisplays:Array<Dynamic>;
    var scene:Sprite;

    public function new(scene:Sprite, message:String, colors:Hash<Int>, flatFont:FlatFont):Void {

        this.scene = scene;
        this.colors = colors;
        this.flatFont = flatFont;
        fontBD = flatFont.getBitmapDataClone();

        //*
        buildText();
        buildCharDisplays();
        populateText(message);
        populateCharDisplays();
        /**/

        /*
        var bitmap = new Bitmap(fontBD);
        scene.addChild(bitmap);
        /**/
    }

    function buildText():Void {
        chars = [];
        for (y in 0...Constants.NUM_ROWS) {
            chars[y] = [];
            for (x in 0...Constants.NUM_COLUMNS) {
                chars[y][x] = " ";
            }
        }
    }

    function buildCharDisplays():Void {

        var container = new Sprite();
        var charRect:Rectangle = new Rectangle();
        charRect.width  = flatFont.charWidth;
        charRect.height = flatFont.charHeight;

        charDisplays = [];
        for (y in 0...Constants.NUM_ROWS) {
            for (x in 0...Constants.NUM_COLUMNS) {
                var billboard:Billboard2D = new Billboard2D(fontBD, flatFont.getCharMatrix(" "), charRect);
                billboard.width = Constants.LETTER_WIDTH;
                billboard.height = Constants.LETTER_HEIGHT;
                billboard.blendMode = BlendMode.ADD;
                billboard.x = -billboard.width  * 0.5;
                billboard.y = -billboard.height * 0.5;

                var sp = new Sprite();

                /*
                sp.graphics.beginFill(0xFF0000);
                sp.graphics.drawCircle(0, 0, 1);
                sp.graphics.endFill();
                /**/

                sp.addChild(billboard);
                sp.x = (x + 0.5) * Constants.LETTER_WIDTH  + Constants.MARGIN;
                sp.y = (y + 0.5) * Constants.LETTER_HEIGHT + Constants.MARGIN;

                var rand:Float = Math.random();
                container.addChild(sp);

                charDisplays.push({
                    text:{char:" ", x:x, y:y},
                    display:{bd:fontBD, billboard:billboard, sp:sp, rect:charRect},
                });
            }
        }

        scene.addChild(container);
    }

    function populateText(message:String):Void {
        var x = 0;
        var y = 0;
        for (ike in 0...message.length) {
            var char = message.charAt(ike);

            if (char == "\n" || chars[y][x] == null) {
                y++;
                x = 0;
            } else {
                if (char != "\n") chars[y][x] = char;
                x++;
            }

            if (y > chars.length) break;
        }
    }

    function populateCharDisplays():Void {
        for (charDisplay in charDisplays) {
            var textComponent = charDisplay.text;
            var display = charDisplay.display;

            var char = chars[textComponent.y][textComponent.x];

            if (textComponent.char != char) {
                textComponent.char = char;

                display.billboard.transform.colorTransform = ColorUtils.tint(colors.get(char), 0.0);
                display.billboard.update(display.bd, flatFont.getCharMatrix(char), display.rect);
                textComponent.char = char;
            }
        }
    }
}
