package;

import massive.munit.TestRunner;

import openfl.Assets.*;
import flash.Lib;

import net.rezmason.gl.utils.UtilitySet;
import net.rezmason.utils.FlatFont;
import net.rezmason.scourge.textview.TestStrings;

class Scourge {

    static var fonts:Map<String, FlatFont>;
    static var utils:UtilitySet;

    public static function main():Void {
        trace('\n${TestStrings.SPLASH}');

        fonts = new Map();
        for (name in ['source', 'profont', 'full']) {
            var path = 'assets/flatfonts/${name}_flat';
            fonts[name] = new FlatFont(getBitmapData('$path.png'), getText('$path.json'));
        }

        utils = new UtilitySet(Lib.current.stage, init);

        // test();
    }

    static function test():Void {
        var client = new SimpleTestClient();
        var runner:TestRunner = new TestRunner(client);
        runner.completionHandler = function(b) trace(client.output);
        runner.run([TestSuite]);
    }

    static function init():Void {
        new net.rezmason.scourge.textview.TextDemo(utils, Lib.current.stage, fonts);
        // new net.rezmason.scourge.textview.Lab(utils, Lib.current.stage, fonts);
        // new net.rezmason.scourge.textview.BasicSetup(utils, Lib.current.stage, fonts);
    }
}
