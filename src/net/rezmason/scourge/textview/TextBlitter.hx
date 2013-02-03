package net.rezmason.scourge.textview;

import nme.display.BitmapData;
import nme.display.BlendMode;
import nme.display.Sprite;
import nme.display.Shape;
import nme.geom.ColorTransform;
import nme.geom.Matrix;
import nme.geom.Rectangle;

import net.rezmason.utils.FlatFont;

using Lambda;

typedef Component = {};

typedef Entity = {
    var id(default, null):Int;
    var components(default, null):Hash<Component>;
}

class Entities {
    private static var entities:Array<Entity> = [];
    private static var __entityIDs:Int = 0;

    public static function create():Entity {
        var ent:Entity = {id:__entityIDs++, components:new Hash<Component>()};
        entities.push(ent);
        return ent;
    }

    public static function fetch(query:Array<String>):Array<Entity> {
        var response:Array<Entity> = [];
        for (ent in entities) {
            var valid:Bool = true;
            for (key in query) {
                if (!ent.components.exists(key)) {
                    valid = false;
                    break;
                }
            }
            if (valid) response.push(ent);
        }

        return response;
    }
}

class ComponentIDs {
    public static inline var TEXT:String = "C_text";
    public static inline var DISPLAY:String = "C_display";
    public static inline var THROB:String = "C_throb";
}

typedef TextComponent = {>Component,
    var char:String;
    var x:Int;
    var y:Int;
}

typedef DisplayComponent = {>Component,
    var bd:BitmapData;
    var rect:Rectangle;
    var bmp:ShapeBitmap;
    var sp:Sprite;
}

typedef ThrobComponent = {>Component,
    var throbTime:Float;
}

class TextBlitter {

    var chars:Array<Array<String>>;
    var colors:Hash<Int>;
    var fontBD:BitmapData;
    var flatFont:FlatFont;
    var systems:Array<System>;

    public function new(scene:Sprite, message:String, colors:Hash<Int>, flatFont:FlatFont):Void {

        this.colors = colors;
        this.flatFont = flatFont;
        fontBD = flatFont.getBitmapDataClone();

        var container = new Sprite();
        var charRect:Rectangle = new Rectangle();
        charRect.width  = flatFont.charWidth;
        charRect.height = flatFont.charHeight;

        chars = [];

        for (y in 0...Constants.NUM_ROWS) {
            chars[y] = [];
            for (x in 0...Constants.NUM_COLUMNS) {
                var char:String = message.charAt(Std.random(message.length));

                char = " ";

                var bmp:ShapeBitmap = new ShapeBitmap(fontBD, flatFont.getCharMatrix(char), charRect);
                bmp.width = Constants.LETTER_WIDTH;
                bmp.height = Constants.LETTER_HEIGHT;
                bmp.blendMode = BlendMode.ADD;
                bmp.x = -bmp.width  * 0.5;
                bmp.y = -bmp.height * 0.5;

                var sp = new Sprite();

                /*
                sp.graphics.beginFill(0xFF0000);
                sp.graphics.drawCircle(0, 0, 1);
                sp.graphics.endFill();
                */

                sp.addChild(bmp);
                sp.x = (x + 0.5) * Constants.LETTER_WIDTH  + Constants.MARGIN;
                sp.y = (y + 0.5) * Constants.LETTER_HEIGHT + Constants.MARGIN;

                var rand:Float = Math.random();
                container.addChild(sp);

                chars[y][x] = char;
                var ent:Entity = Entities.create();
                ent.components.set(ComponentIDs.TEXT, {char:char, x:x, y:y});
                ent.components.set(ComponentIDs.DISPLAY, {bd:fontBD, bmp:bmp, sp:sp, rect:charRect});
                ent.components.set(ComponentIDs.THROB, {throbTime:Math.random() * 1});
            }
        }

        nme.Lib.trace([chars[0].length, chars.length]);

        scene.addChild(container);
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

        systems = [];
        systems.push(new StupidSystem(chars, colors, flatFont));
        systems.push(new ThrobSystem());
        updateAll(null);
        scene.addEventListener("enterFrame", updateAll);
    }

    function updateAll(_) { for (system in systems) system.update(); }
}

interface System {
    function update():Void;
}

class StupidSystem implements System {

    var chars:Array<Array<String>>;
    var colors:Hash<Int>;
    var flatFont:FlatFont;

    public function new(chars:Array<Array<String>>, colors:Hash<Int>, flatFont:FlatFont):Void {
        this.chars = chars;
        this.colors = colors;
        this.flatFont = flatFont;
    }

    public function update():Void {
        for (ent in Entities.fetch([ComponentIDs.TEXT, ComponentIDs.DISPLAY])) {
            var textComponent:TextComponent = cast ent.components.get(ComponentIDs.TEXT);
            var display:DisplayComponent = cast ent.components.get(ComponentIDs.DISPLAY);

            var char = chars[textComponent.y][textComponent.x];

            if (textComponent.char != char) {
                textComponent.char = char;

                display.bmp.transform.colorTransform = tint(colors.get(char), 0.0);
                display.bmp.update(display.bd, flatFont.getCharMatrix(char), display.rect);
                textComponent.char = char;
            }
        }
    }

    private inline static function tint(color:Null<Int>, inverseVid:Float = 0):ColorTransform {
        var ct:ColorTransform = new ColorTransform();

        if (color == null) color = 0xFFFFFF;

        ct.redMultiplier   = (color >> 16 & 0xFF) / 0xFF;
        ct.greenMultiplier = (color >>  8 & 0xFF) / 0xFF;
        ct.blueMultiplier  = (color >>  0 & 0xFF) / 0xFF;

        inverseVid = clamp(inverseVid, 0, 1);
        ct.alphaOffset = Std.int(0xFF * inverseVid);
        ct.alphaMultiplier = if (inverseVid > 0.5) 1 - 2 * inverseVid else 1;

        return ct;
    }

    private inline static function clamp(val:Float, min:Float, max:Float):Float {
        return if (val < min) min else if (val > max) max else val;
    }
}

class ThrobSystem implements System {

    public function new():Void {}

    public function update():Void {
        for (ent in Entities.fetch([ComponentIDs.TEXT, ComponentIDs.DISPLAY])) {
            var text:TextComponent = cast ent.components.get(ComponentIDs.TEXT);
            var display:DisplayComponent = cast ent.components.get(ComponentIDs.DISPLAY);
            var throb:ThrobComponent = cast ent.components.get(ComponentIDs.THROB);

            if (text.char != " ") {
                throb.throbTime = (throb.throbTime + 0.02) % 1;
                var amp:Float = Math.sin(throb.throbTime * Math.PI * 2);
                display.sp.scaleX = display.sp.scaleY = (amp * 0.4 + 1.5) * 1.3;
            }
        }
    }
}

class ShapeBitmap extends Shape {

    public function new(bitmapData:BitmapData, mat:Matrix, rect:Rectangle):Void {
        super();
        update(bitmapData, mat, rect);
    }

    public function update(bitmapData:BitmapData, mat:Matrix, rect:Rectangle):Void {
        graphics.clear();
        graphics.beginBitmapFill(bitmapData, mat, false, true);
        graphics.drawRect(rect.x, rect.y, rect.width, rect.height);
        graphics.endFill();
    }

    public function clear():Void {
        graphics.clear();
    }
}
