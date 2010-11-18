import flash.display.Sprite;
import flash.Lib;

import net.rezmason.scourge.flash.Board;
import net.rezmason.scourge.Game;

class ScourgeFlashProject extends Sprite {
	public static function main():Void { 
		var defaultGrid:String = Lib.current.loaderInfo.parameters.defaultGrid;
		if (defaultGrid == null) defaultGrid = "";
		var board:Board = new Board(new Game(defaultGrid.split(",")), Lib.current); 
		var splash:Array<String> = [
			" %%%%    %%%      %%%    %   %    %%%%      %%%%    %%%", 
			"%       %   %    %   %   %   %    %   %    %   %   %   %", 
			"%%%%%   %        %   %   %   %    %%%%      %%%%   %%%%%", 
			"    %   %   %    %   %   %   %    %   %        %   %    ", 
			"%%%%     %%%      %%%     %%%     %   %    %%%%     %%%%", 
			"Single-Celled Organisms Undergo Rapid Growth Enhancement",
		];
		//flash.Lib.trace(splash.join("\n"));
	}
}