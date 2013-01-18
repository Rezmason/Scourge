package net.rezmason.scourge.view;

import nme.Assets;
import nme.display.Sprite;
import nme.text.AntiAliasType;
import nme.text.TextField;
import nme.text.TextFormat;

class TextThing {

    public function new(scene:Sprite, message:String, colors:Hash<Int>):Void {

        var htmlText:String = "";
        for (ike in 0...message.length) {
            var char = message.charAt(ike);
            if (colors.exists(char)) char = colorize(char, colors.get(char));
            htmlText += char;
        }

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
    }

    private function colorize(str:String, color:Int):String {
        return "<FONT COLOR='#" + StringTools.hex(color) + "'>" + str + "</FONT>";
    }
}
