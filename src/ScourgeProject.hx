import flash.display.Sprite;

import net.rezmason.scourge.Board;
import net.rezmason.scourge.Game;

class ScourgeProject extends Sprite {
	public static function main():Void { 
		var board:Board = new Board(new Game(), flash.Lib.current); 
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