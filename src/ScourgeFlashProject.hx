import flash.display.Sprite;
import flash.Lib;

import net.rezmason.scourge.flash.Board;
import net.rezmason.scourge.Game;

class ScourgeFlashProject extends Sprite {
	public static function main():Void { 
		
		var defaultGrid:String = Lib.current.loaderInfo.parameters.defaultGrid;
		var numPlayers:Int = Std.parseInt(Lib.current.loaderInfo.parameters.numPlayers);
		if (defaultGrid == null) defaultGrid = "-1";
		if (numPlayers == 0) numPlayers = 4;
		var board:Board = new Board(new Game(defaultGrid.split(",")), Lib.current, numPlayers); 
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