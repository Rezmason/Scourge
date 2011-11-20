import flash.display.Sprite;
import flash.events.Event;
import flash.Lib;

#if oldview
import net.rezmason.scourge.old.Board;
#else
import net.rezmason.scourge.swipe.SwipeView;
#end
import net.rezmason.scourge.model.Game;
import net.rezmason.scourge.Common;

class Scourge {

	public static function main():Void {
		Lib.current.loaderInfo.addEventListener(Event.INIT, init);
	}

	public static function init(?event:Event):Void {
		Lib.current.loaderInfo.removeEventListener("init", init);

		var params:Dynamic = Lib.current.loaderInfo.parameters;

		var defaultGrid:String = params.defaultGrid;
		var numPlayers:Int = Std.parseInt(params.numPlayers);
		var circular:Bool = (params.circular == "true" || params.circular == "1");
		var duration:Float = params.duration;

		if (defaultGrid == null) defaultGrid = "-1";
		if (numPlayers == 0) numPlayers = 4;
		if (Math.isNaN(duration)) duration = 0;

		var options:GameOptions = {
			numPlayers:numPlayers,
			circular:circular,
			duration:duration,
		};

		var game:Game = new Game(defaultGrid.split(","));
		#if oldview
		var board:Board = new Board(game, Lib.current, options);
		#else
		var view:SwipeView = new SwipeView(game, Lib.current, options);
		#end

		var splash:Array<String> = [
			" %%%%    %%%      %%%    %   %    %%%%      %%%%    %%% ",
			"%       %   %    %   %   %   %    %   %    %   %   %   %",
			"%%%%%   %        %   %   %   %    %%%%      %%%%   %%%%%",
			"    %   %   %    %   %   %   %    %   %        %   %    ",
			"%%%%     %%%      %%%     %%%     %   %    %%%%     %%%%",
			"Single-Celled Organisms Undergo Rapid Growth Enhancement",
		];

		//Lib.trace(splash.join("\n"));
	}
}
