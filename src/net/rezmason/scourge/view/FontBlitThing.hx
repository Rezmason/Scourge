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
    public static inline var CHARACTER:String = "C_character";
    public static inline var RENDERABLE:String = "C_renderable";
}

typedef CharacterComponent = {>Component,
    var char:String;
    var x:Int;
    var y:Int;
}

typedef RenderableComponent = {>Component,
    var bd:BitmapData;
    var bmp:Bitmap;
    var sp:Sprite;
    var _t:Float;
}

class FontBlitThing {

    static inline var STAGE_WIDTH:Int = 800;
    static inline var STAGE_HEIGHT:Int = 600;

    var chars:Array<Array<String>>;
    var colors:Hash<Int>;
    var charBitmaps:Hash<BitmapData>;
    var systems:Array<System>;

    public function new(scene:Sprite, message:String, colors:Hash<Int>):Void {

        this.colors = colors;

        var requiredChars:Array<String> = [];

        for (ike in 0...message.length) {
            var char = message.charAt(ike);
            if (char != "\n" && !requiredChars.has(char)) requiredChars.push(char);
        }

        var font = Assets.getFont("assets/ProFontX.ttf");
        var format = new TextFormat(font.fontName, 14, 0xFFFFFF);

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

        bounds.right -= 1;

        var wid:Int = Std.int(bounds.width ) * mag;
        var hgt:Int = Std.int(bounds.height) * mag;

        var clearTypeDist:Float = 0.6;
        var orangeCT:ColorTransform = new ColorTransform(1, 0.6, 0.1, 1);
        var cyanCT:ColorTransform = new ColorTransform(0.1, 0.6, 1.0, 1);

        charBitmaps = new Hash<BitmapData>();

        for (char in requiredChars) {
            textField.text = char;
            var bd = new BitmapData(wid, hgt, true, 0x01000000);
            var mat = new Matrix();
            mat.tx = bounds.left;
            mat.ty = bounds.top;
            mat.scale(mag, mag);
            //bd.noise(0);

            //bd.draw(textField, mat, null, BlendMode.NORMAL);

            mat.translate(-clearTypeDist, 0);
            bd.draw(textField, mat, cyanCT, BlendMode.ADD);
            mat.translate(clearTypeDist, 0);
            mat.translate(clearTypeDist, 0);
            bd.draw(textField, mat, orangeCT, BlendMode.ADD);

            charBitmaps.set(char, bd);

            if (~/\s+/g.match(char)) bd.fillRect(bd.rect, 0x0);
        }

        var container = new Sprite();

        chars = [];

        var numRows:Int = 34;
        var numColumns:Int = 85;
        var margin:Int = 5;

        var letterWidth = (STAGE_WIDTH - margin * 2) / numColumns;
        var letterHeight = (scene.stage.stageHeight - margin * 2) / numRows;
        var letterScale:Float = 1.4;

        for (y in 0...numRows) {
            chars[y] = [];
            for (x in 0...numColumns) {
                var char:String = message.charAt(Std.random(message.length));

                char = " ";

                var bd = charBitmaps.get(char);

                var bmp = new Bitmap(bd);
                bmp.smoothing = true;
                bmp.width = letterWidth * letterScale;
                bmp.height = letterHeight * letterScale;
                bmp.x = -bmp.width / 2;
                bmp.y = -bmp.height / 2;
                bmp.blendMode = BlendMode.ADD;

                var sp = new Sprite();

                /*
                sp.graphics.beginFill(0xFF0000);
                sp.graphics.drawCircle(0, 0, 1);
                sp.graphics.endFill();
                */

                sp.addChild(bmp);
                sp.x = x * letterWidth  + sp.width / 2;
                sp.y = y * letterHeight + sp.height / 2;

                var rand:Float = Math.random();
                container.addChild(sp);

                chars[y][x] = char;
                var ent:Entity = Entities.create();
                ent.components.set(ComponentIDs.CHARACTER, {char:char, x:x, y:y});
                ent.components.set(ComponentIDs.RENDERABLE, {bd:bd, bmp:bmp, sp:sp, _t:Math.random()});
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
        container.x = (STAGE_WIDTH  - container.width ) / 2;
        container.y = (STAGE_HEIGHT - container.height) / 2;

        systems = [];
        systems.push(new CharacterSystem(chars, colors, charBitmaps));
        systems.push(new RenderableSystem());
        updateAll(null);
        scene.addEventListener("enterFrame", updateAll);
    }

    function updateAll(_) { for (system in systems) system.update(); }
}

interface System {
    function update():Void;
}

class CharacterSystem implements System {

    var chars:Array<Array<String>>;
    var colors:Hash<Int>;
    var charBitmaps:Hash<BitmapData>;

    public function new(chars:Array<Array<String>>, colors:Hash<Int>, charBitmaps:Hash<BitmapData>):Void {
        this.chars = chars;
        this.colors = colors;
        this.charBitmaps = charBitmaps;
    }

    public function update():Void {
        for (ent in Entities.fetch([ComponentIDs.CHARACTER, ComponentIDs.RENDERABLE])) {
            var characterComponent:CharacterComponent = cast ent.components.get(ComponentIDs.CHARACTER);
            var renderableComponent:RenderableComponent = cast ent.components.get(ComponentIDs.RENDERABLE);

            var char = chars[characterComponent.y][characterComponent.x];

            if (characterComponent.char != char) {
                characterComponent.char = char;

                renderableComponent.bmp.transform.colorTransform = tint(colors.get(char), 0);
                renderableComponent.bmp.bitmapData = charBitmaps.get(char);
                renderableComponent.bmp.smoothing = true;
                characterComponent.char = char;
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
        ct.alphaMultiplier = if (inverseVid > 0.8) 1 - 2 * inverseVid else 1;

        return ct;
    }

    private inline static function clamp(val:Float, min:Float, max:Float):Float {
        return if (val < min) min else if (val > max) max else val;
    }
}

class RenderableSystem implements System {
    public function new():Void {}

    public function update():Void {
        for (ent in Entities.fetch([ComponentIDs.CHARACTER, ComponentIDs.RENDERABLE])) {
            var characterComponent:CharacterComponent = cast ent.components.get(ComponentIDs.CHARACTER);
            var renderableComponent:RenderableComponent = cast ent.components.get(ComponentIDs.RENDERABLE);

            if (characterComponent.char != " ") {
                renderableComponent._t = (renderableComponent._t + 0.02) % 1;
                var amp:Float = Math.sin(renderableComponent._t * Math.PI * 2);
                renderableComponent.sp.scaleX = renderableComponent.sp.scaleY = amp * 0.3 + 1.2;
                renderableComponent.sp.alpha = 1.3 + 0.4 * amp;
            }
        }
    }
}
