package;

import flash.Lib;
import net.rezmason.gl.utils.UtilitySet;

class ScourgeLab {

    static var utils:UtilitySet;

    public static function main():Void {
        #if flash Lib.redirectTraces(); #end
        new net.rezmason.scourge.Lab(Lib.current.stage);
    }
}
