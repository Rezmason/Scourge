package net.rezmason.scourge.textview;

//import nme.display.Bitmap;
import nme.display.Stage;

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
    var flatFont:FlatFont;
    var things:Array<Thing>;
    var projection:Projection;
    var charSpriteManager:CharSpriteManager;

    public function new(stage:Stage, message:String, colors:IntHash<Int>, flatFont:FlatFont):Void {

        this.colors = colors;
        charSpriteManager = new CharSpriteManager(stage, flatFont, 0.8);

        //*
        buildText();
        buildThings();
        projection = {cx:Constants.VANISHING_POINT_X, cy:Constants.VANISHING_POINT_Y, fl:Constants.FOCAL_LENGTH};
        populateText(message);
        populateThings();
        /**/

        /*
        var bitmap = new Bitmap(flatFont.getBitmapDataClone());
        stage.addChild(bitmap);
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

        things = [];
        for (ty in 0...Constants.NUM_ROWS) {
            for (tx in 0...Constants.NUM_COLUMNS) {

                var charSprite:CharSprite = charSpriteManager.createCharSprite();

                things.push({
                    text:{code:null, tx:tx, ty:ty},
                    display:{charSprite:charSprite},
                    position:{
                        x:(tx + 0.5) * Constants.LETTER_WIDTH  + Constants.MARGIN,
                        y:(ty + 0.5) * Constants.LETTER_HEIGHT + Constants.MARGIN,
                        z:(Math.sin(tx * 0.2) * 0.5 + 0.5) * (Math.sin(ty * 0.3) * 0.5 + 0.5) * Constants.MAX_DEPTH,
                        //z:Constants.MAX_DEPTH,
                    },
                    swell:{val: 1.0 + tx / Constants.NUM_COLUMNS},
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

            charSpriteManager.updateText(charSprite, code, color, 0.0);
            charSpriteManager.updatePosition(charSprite, pos.x, pos.y, pos.z, projection.cx, projection.cy, projection.fl);
            charSpriteManager.updateSwell(charSprite, swell.val);
        }
    }
}
