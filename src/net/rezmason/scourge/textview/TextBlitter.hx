package net.rezmason.scourge.textview;

import nme.display.BitmapData;
import nme.display.Sprite;
import nme.geom.Rectangle;

import net.rezmason.utils.FlatFont;
import net.rezmason.utils.FatChar;

typedef Display = {charSprite:CharSprite};
typedef Text = {code:Null<Int>, tx:Int, ty:Int};
typedef Position = {x:Float, y:Float, z:Float};
typedef Swell = {val:Float};
typedef Projection = {cx:Float, cy:Float, fl:Float};

typedef Thing = {
    display:Display,
    text:Text,
    position:Position,
    swell:Swell,
}

class TextBlitter {

    var fatChars:Array<Array<FatChar>>;
    var colors:IntHash<Int>;
    var fontBD:BitmapData;
    var flatFont:FlatFont;
    var things:Array<Thing>;
    var scene:Sprite;
    var projection:Projection;

    public function new(scene:Sprite, message:String, colors:IntHash<Int>, flatFont:FlatFont):Void {

        this.scene = scene;
        this.colors = colors;
        this.flatFont = flatFont;
        fontBD = flatFont.getBitmapDataClone();

        //*
        buildText();
        buildThings();
        projection = {cx:Constants.VANISHING_POINT_X, cy:Constants.VANISHING_POINT_Y, fl:Constants.FOCAL_LENGTH};
        populateText(message);
        populateThings();
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

    function buildThings():Void {

        var charRect:Rectangle = new Rectangle();
        charRect.width  = flatFont.charWidth;
        charRect.height = flatFont.charHeight;

        things = [];
        for (ty in 0...Constants.NUM_ROWS) {
            for (tx in 0...Constants.NUM_COLUMNS) {

                var charSprite:CharSprite = new CharSprite(scene, fontBD, flatFont.getCharMatrix(" "), charRect);

                things.push({
                    text:{code:null, tx:tx, ty:ty},
                    display:{charSprite:charSprite},
                    position:{
                        x:(tx + 0.5) * Constants.LETTER_WIDTH  + Constants.MARGIN,
                        y:(ty + 0.5) * Constants.LETTER_HEIGHT + Constants.MARGIN,
                        z:(Math.sin(tx * 0.2) * 0.5 + 0.5) * (Math.sin(ty * 0.3) * 0.5 + 0.5) * Constants.MAX_DEPTH,
                        //z:Constants.MAX_DEPTH,
                    },
                    swell:{val: 0.6 + tx / Constants.NUM_COLUMNS},
                });
            }
        }
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

    function populateThings():Void {

        for (thing in things) {
            var charSprite = thing.display.charSprite;
            var pos = thing.position;
            var text = thing.text;
            var swell = thing.swell;

            var code:Int = fatChars[text.ty][text.tx].code;
            text.code = code;

            var color:Int = 0xFFFFFF;
            if (colors.exists(code)) color = colors.get(code);

            charSprite.updatePosition(pos.x, pos.y, pos.z, projection.cx, projection.cy, projection.fl);
            charSprite.updateText(flatFont.getCharCodeMatrix(code), color, 0.0);
            charSprite.updateSwell(swell.val);
        }
    }
}
