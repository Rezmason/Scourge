//import net.rezmason.scourge.js.Board;
import net.rezmason.scourge.Game;

class ScourgeJSProject {
	public static function main():Void {
		haxe.Firebug.redirectTraces();
		/*
		var defaultGrid:String = Lib.current.loaderInfo.parameters.defaultGrid;
		if (defaultGrid == null) defaultGrid = "";
		var board:Board = new Board(new Game(defaultGrid.split(",")), Lib.current); 
		*/
		
		var splash:Array<String> = [
			" %%%%    %%%      %%%    %   %    %%%%      %%%%    %%%", 
			"%       %   %    %   %   %   %    %   %    %   %   %   %", 
			"%%%%%   %        %   %   %   %    %%%%      %%%%   %%%%%", 
			"    %   %   %    %   %   %   %    %   %        %   %    ", 
			"%%%%     %%%      %%%     %%%     %   %    %%%%     %%%%", 
			"Single-Celled Organisms Undergo Rapid Growth Enhancement",
		];
		trace("\n" + splash.join("\n"));
	}
}