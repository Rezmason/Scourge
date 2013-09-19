import flash.display.Sprite;
import flash.events.Event;
import flash.Lib;

#if proto
	import view.Board;
	import model.Game;
	import swipe.SwipeView;
#else

#end
import Common;

class Proto {

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

		#if proto
			var game:Game = new Game(defaultGrid.split(","));
			var board:Board = new Board(game, Lib.current, options);
			//var view:SwipeView = new SwipeView(game, Lib.current, options);
		#else

		#end
	}
}
