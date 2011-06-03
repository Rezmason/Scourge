import net.rezmason.scourge.Board;
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
		var defaultGrid:String = untyped __js__("window.defaultGrid");
		var numPlayers:Int = untyped __js__("window.numPlayers");
		if (defaultGrid == null) defaultGrid = "-1";
		if (numPlayers == 0) numPlayers = 4;
		var viewTarget = Lib.document.getElementById("scourge:target");
		
		var board:Board = new Board(new Game([]), viewTarget, numPlayers);
		
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