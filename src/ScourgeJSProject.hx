import net.rezmason.scourge.js.Board;
import net.rezmason.scourge.Game;
import js.Dom;
import js.Lib;

class ScourgeJSProject {
	
	public static function main():Void {
		haxe.Firebug.redirectTraces();
		Lib.window.onload = begin;
	}
	
	private static function begin(event:Event):Void {
		Lib.window.onload = null;
		
		//var defaultGrid:String = Lib.current.loaderInfo.parameters.defaultGrid;
		//if (defaultGrid == null) defaultGrid = "-1";
		
		var viewTarget = Lib.document.getElementById("thingy");
		var board:Board = new Board(new Game([]), viewTarget);
		
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