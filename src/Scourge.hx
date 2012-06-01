import flash.display.Sprite;
import flash.events.Event;
import flash.Lib;

class Scourge {

    public static function main():Void {
        Lib.current.loaderInfo.addEventListener(Event.INIT, init);
    }

    public static function init(?event:Event):Void {
        Lib.current.loaderInfo.removeEventListener("init", init);

        var params:Dynamic = Lib.current.loaderInfo.parameters;



        var splash:Array<String> = [
            " %%%%    %%%      %%%    %   %    %%%%      %%%%    %%% ",
            "%       %   %    %   %   %   %    %   %    %   %   %   %",
            "%%%%%   %        %   %   %   %    %%%%      %%%%   %%%%%",
            "    %   %   %    %   %   %   %    %   %        %   %    ",
            "%%%%     %%%      %%%     %%%     %   %    %%%%     %%%%",
            "Single-Celled Organisms Undergo Rapid Growth Enhancement",
        ];

        Lib.trace(splash.join("\n"));
    }
}
