package net.rezmason.scourge.view;

import nme.Assets;
import nme.display.Sprite;
import nme.text.AntiAliasType;
import nme.text.TextField;
import nme.text.TextFormat;

typedef Character = {
    var x:Int;
    var y:Int;
    var color:Null<Int>;
    var char:String;
}

class BoardThing {

    public function new(scene:Sprite, message:String, colors:Hash<Int>):Void {

        var characters:Array<Character> = [];

        var x:Int = 0;
        var y:Int = 0;
        for (ike in 0...message.length) {
            var char = message.charAt(ike);
            if (char == "\n") {
                y++;
                x = 0;
            } else {
                characters.push({x:x, y:y, char:char, color:colors.get(char)});
                x++;
            }
        }

        var x = 2.5;
        var y = 5;

        var wid = 9.31;
        var hgt = 17;

        for (character in characters) {
            if (character.char == " ") continue;
            var color:Null<Int> = character.color;
            if (color == null) color = 0xFFFFFF;
            scene.graphics.beginFill(color, 0.5);
            scene.graphics.drawRect(x + character.x * wid, y + character.y * hgt, wid, hgt);
            scene.graphics.endFill();
        }

        /*
        var font = Assets.getFont("assets/ProFontX.ttf");
        var format = new TextFormat(font.fontName, 14, 0xFFFFFF);

        var textField = new TextField();
        textField.antiAliasType = AntiAliasType.ADVANCED;
        textField.thickness = 100;
        textField.sharpness = -400;
        textField.defaultTextFormat = format;
        textField.selectable = false;
        textField.embedFonts = true;
        textField.width = 800;
        textField.height = 600;
        textField.x = 0;
        textField.y = 0;

        textField.htmlText = htmlText;

        scene.addChild(textField);
        */
    }
}
