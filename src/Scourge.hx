package;

import flash.Lib;

import net.rezmason.gl.utils.UtilitySet;
import net.rezmason.scourge.textview.Strings;

class Scourge {

    static var utils:UtilitySet;

    public static function main():Void {
        #if flash Lib.redirectTraces(); #end
        trace('\n${Strings.SPLASH}');
        utils = new UtilitySet(Lib.current.stage, init);
    }

    static function init():Void {
        new net.rezmason.scourge.textview.TextDemo(utils, Lib.current.stage);
        // new net.rezmason.scourge.textview.Lab(utils, Lib.current.stage);
        // new net.rezmason.scourge.textview.waves.WaveDemo(Lib.current);
    }
}
