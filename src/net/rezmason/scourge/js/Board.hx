package net.rezmason.scourge.js;

import js.Dom;
import js.Lib;
//import Raphael;
import net.rezmason.scourge.Game;

import com.gskinner.display.Stage;
import com.gskinner.display.Container;
import com.gskinner.display.Shape;

class Board {
	
	private var _game:Game;
	private var _div:HtmlDom;
	private var _canvas:HtmlDom;
	private var stage:Stage;
	private var scene:Container;
	
	private var debugNumPlayers:Int;
	
	private var width:Float;
	private var height:Float;
	
	public function new(__game:Game, __div:HtmlDom, __debugNumPlayers:Int) {
		
		_game = __game;
		_div = __div;
		debugNumPlayers = __debugNumPlayers;
		
		width = -1;
		height = -1;
		
		_div.innerHTML = "<canvas id=\"scourge:canvas\"></canvas>";
		_canvas = _div.firstChild;
		stage = new Stage(_canvas);
		scene = new Container();
		stage.addChild(scene);
		
		initialize();
	}
	
	private function initialize():Void {
		var canvas:HtmlDom = Lib.document.getElementById("testCanvas");
		var stage:Stage = new Stage(canvas);
		/*
		var paper = new Raphael(_div.id, "100%", "100%");
		
		var circle = paper.rect()
		circle.attr("fill", "#f00");
		circle.attr("stroke", "#fff");
		*/
		
		_div.onmouseup = mouseHandler;
		Lib.document.onkeydown = Lib.document.onkeyup = keyHandler;
		Lib.window.onresize = resize;
		resize(null);
	}
	
	private function resize(event:Event):Void {
		if (width == _div.offsetWidth && height == _div.offsetHeight) return;
		
		width = _div.offsetWidth;
		height = _div.offsetHeight;
		Reflect.setField(_canvas, "width", width);
		Reflect.setField(_canvas, "height", height);
		
		var shp:Shape = new Shape();
		
		shp.setFillStyle("#" + StringTools.hex(Std.int(Math.random() * 0xFFFFFF)));
		shp.fillRect(0, 0, Math.random() * 100, Math.random() * 100);
		shp.x = Math.random() * _div.offsetWidth;
		shp.y = Math.random() * _div.offsetHeight;
		shp.fill();
		
		scene.addChild(shp);
		
		stage.tick();
	}
	
	private function keyHandler(event:Event):Void {
		
	}
	
	private function mouseHandler(event:Event):Void {
		
	}
}