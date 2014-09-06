package;

import flash.Lib;
import openfl.Assets;

class Scourge {

    public static function main():Void {
        #if flash Lib.redirectTraces(); #end
        trace('\n${Assets.getText('text/splash.txt')}');
        new net.rezmason.scourge.Context(Lib.current.stage);
    }
}
