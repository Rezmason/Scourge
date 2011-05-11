import flash.display.Sprite;
import flash.Lib;

import net.rezmason.scourge.Board;
import net.rezmason.scourge.Game;

class ScourgeFlashProject extends Sprite {
	public static function main():Void { 
		
		var defaultGrid:String = Lib.current.loaderInfo.parameters.defaultGrid;
		var params:Dynamic = Lib.current.loaderInfo.parameters;
		var numPlayers:Int = Std.parseInt(params.numPlayers);
		var circular:Bool = (params.circular == "true" || params.circular == "1");
		var duration:Float = params.duration;
		if (defaultGrid == null) defaultGrid = "-1";
		if (numPlayers == 0) numPlayers = 4;
		if (Math.isNaN(duration)) duration = 0;
		var board:Board = new Board(new Game(defaultGrid.split(",")), Lib.current, {numPlayers:numPlayers, circular:circular, duration:duration}); 
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