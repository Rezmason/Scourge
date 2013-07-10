package;

import openfl.Assets.*;
import flash.Lib;

import net.rezmason.utils.FlatFont;
import net.rezmason.scourge.textview.TestStrings;

class Scourge {

    public static function main():Void {
        trace('\n${TestStrings.SPLASH}');

        var fonts = new Map();
        for (name in ['source', 'profont', 'full']) {
            var path = 'assets/flatfonts/${name}_flat';
            fonts[name] = new FlatFont(getBitmapData('$path.png'), getText('$path.json'));
        }

        new net.rezmason.scourge.textview.TextDemo(Lib.current.stage, fonts);
    }
}
