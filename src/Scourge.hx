import flash.display.Sprite;
import flash.events.Event;
import flash.Lib;

import net.rezmason.scourge.Board;
import net.rezmason.scourge.Game;

class Scourge {
	
	public static function main():Void {
		Lib.current.loaderInfo.addEventListener(Event.INIT, init);
	}
	
	public static function init(?event:Event):Void { 
		var params:Dynamic;
		
		Lib.current.loaderInfo.removeEventListener("init", init);
		params = Lib.current.loaderInfo.parameters;
		
		var base = 
			#if js Lib.document.getElementById("scourge:target");
			#else Lib.current;
			#end
		
		var defaultGrid:String = params.defaultGrid;
		var numPlayers:Int = Std.parseInt(params.numPlayers);
		var circular:Bool = (params.circular == "true" || params.circular == "1");
		var duration:Float = params.duration;
		if (defaultGrid == null) defaultGrid = "-1";
		if (numPlayers == 0) numPlayers = 4;
		if (Math.isNaN(duration)) duration = 0;
		var board:Board = new Board(new Game(defaultGrid.split(",")), base, {numPlayers:numPlayers, circular:circular, duration:duration}); 
		var splash:Array<String> = [
			" %%%%    %%%      %%%    %   %    %%%%      %%%%    %%%", 
			"%       %   %    %   %   %   %    %   %    %   %   %   %", 
			"%%%%%   %        %   %   %   %    %%%%      %%%%   %%%%%", 
			"    %   %   %    %   %   %   %    %   %        %   %    ", 
			"%%%%     %%%      %%%     %%%     %   %    %%%%     %%%%", 
			"Single-Celled Organisms Undergo Rapid Growth Enhancement",
		];
		
		//Lib.trace(splash.join("\n"));
	}
}