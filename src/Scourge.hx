package;

import flash.Lib;
import openfl.Assets;
import net.rezmason.gl.utils.UtilitySet;
import net.rezmason.scourge.Strings;

class Scourge {

    static var utils:UtilitySet;

    public static function main():Void {
        #if flash Lib.redirectTraces(); #end
        trace('\n${Assets.getText('text/splash.txt')}');
        utils = new UtilitySet(Lib.current.stage, init);
    }

    static function init():Void {
        new net.rezmason.scourge.Context(utils, Lib.current.stage);
        // new net.rezmason.scourge.Lab(utils, Lib.current.stage);
        // new net.rezmason.scourge.waves.WaveDemo(Lib.current);
    }
}
