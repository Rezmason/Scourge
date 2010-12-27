package net.rezmason.scourge.js;

import js.Dom;
import js.Lib;
//import Raphael;
import net.rezmason.scourge.Game;

import com.gskinner.display.Stage;

class Board {
	
	var _game:Game;
	var _scene:HtmlDom;
	
	public function new(__game:Game, __scene:HtmlDom) {
		
		_game = __game;
		_scene = __scene;
		
		begin(null);
	}
	
	private function begin(event:Event):Void {
		var canvas:HtmlDom = Lib.document.getElementById("testCanvas");
		var stage:Stage = new Stage(canvas);
		/*
		var paper = new Raphael(_scene.id, "100%", "100%");
		
		var circle = paper.rect()
		circle.attr("fill", "#f00");
		circle.attr("stroke", "#fff");
		*/
	}
}