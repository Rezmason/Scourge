package net.rezmason.scourge.textview;

import nme.display.BitmapData;
import nme.display.Bitmap;
import nme.display.BlendMode;
import nme.display.Sprite;
import nme.geom.Rectangle;

import haxe.Utf8;

import net.rezmason.utils.FlatFont;
import net.rezmason.utils.FatChar;

class TextBlitter {

    var fatChars:Array<Array<FatChar>>;
    var colors:IntHash<Int>;
    var fontBD:BitmapData;
    var flatFont:FlatFont;
    var charDisplays:Array<Dynamic>;
    var scene:Sprite;

    public function new(scene:Sprite, message:String, colors:IntHash<Int>, flatFont:FlatFont):Void {

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
        fatChars = [];
        var dummy:FatChar = new FatChar();
        for (y in 0...Constants.NUM_ROWS) {
            fatChars[y] = [];
            for (x in 0...Constants.NUM_COLUMNS) {
                fatChars[y][x] = dummy;
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
                    text:{code:null, x:x, y:y},
                    display:{bd:fontBD, billboard:billboard, sp:sp, rect:charRect},
                });
            }
        }

        scene.addChild(container);
    }

    function populateText(message:String):Void {
        var x = 0;
        var y = 0;
        for (fatChar in FatChar.fromString(message)) {

            if (fatChar.code == null) continue;

            if (fatChar.string == "\n" || fatChars[y] == null || fatChars[y][x] == null) {
                y++;
                x = 0;
            } else {
                if (fatChar.string != "\n") fatChars[y][x] = fatChar;
                x++;
            }

            if (y > fatChars.length) break;
        }
    }

    function populateCharDisplays():Void {
        for (charDisplay in charDisplays) {
            var textComponent = charDisplay.text;
            var display = charDisplay.display;

            var code:Int = fatChars[textComponent.y][textComponent.x].code;

            if (textComponent.code != code) {
                textComponent.code = code;

                var ct = ColorUtils.tint(colors.get(code), 0.0);
                #if neko
                    display.billboard.nmeSetColorTransform(ct);
                #else
                    display.billboard.transform.colorTransform = ct;
                #end

                display.billboard.update(display.bd, flatFont.getCharCodeMatrix(code), display.rect);
                textComponent.code = code;
            }
        }
    }
}
