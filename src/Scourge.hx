package;

class Scourge {
    public static function main():Void {
        #if flash flash.Lib.redirectTraces(); #end
        trace('\n${openfl.Assets.getText('text/splash.txt')}');
        new net.rezmason.scourge.Context();
    }
}
