package;

import flash.Lib;
import net.rezmason.gl.utils.UtilitySet;

class ScourgeLab {

    static var utils:UtilitySet;

    public static function main():Void {
        #if flash Lib.redirectTraces(); #end
        utils = new UtilitySet(Lib.current.stage, init);
    }

    static function init():Void {
        // new net.rezmason.scourge.Context(utils, Lib.current.stage);
        new net.rezmason.scourge.Lab(utils, Lib.current.stage);
        // new net.rezmason.scourge.waves.WaveDemo(Lib.current);
    }
}
