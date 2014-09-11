package;

class ScourgeLab {

    public static function main():Void {
        #if flash flash.Lib.redirectTraces(); #end
        new net.rezmason.scourge.Lab(flash.Lib.current.stage);
    }
}
