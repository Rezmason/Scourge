package net.rezmason.scourge.js;

import js.Dom;
import js.Lib;
import net.rezmason.js.Canvas;

import com.gskinner.display.Stage;
import com.gskinner.display.Container;
import com.gskinner.display.Graphics;
import com.gskinner.display.Shape;

import net.kawa.tween.KTween;
import net.kawa.tween.KTJob;
import net.kawa.tween.easing.Linear;

import net.rezmason.scourge.Common;
import net.rezmason.scourge.Game;
import net.rezmason.scourge.Layout;
import net.rezmason.scourge.Pieces;
import net.rezmason.scourge.Player;
import net.rezmason.scourge.PlayerAction;

class Board {
	
	private var game:Game;
	private var div:HtmlDom;
	private var canvas:Canvas;
	private var stage:Stage;
	private var scene:Container;
	
	inline static var __softSnap:Bool = true; // not sure if I want this
	
	inline static var MIN_WIDTH:Int = 400;
	inline static var MIN_HEIGHT:Int = 300;
	inline static var SNAP_RATE:Float = 0.45;
	
	private var background:Shape;
	private var grid:GameGrid;
	private var bar:Container;
	private var barBackground:Shape;
	private var well:Well;
	private var timerPanel:TimerPanel;
	private var statPanel:StatPanel;
	private var debugNumPlayers:Int;
	
	public function new(__game:Game, __div:HtmlDom, __debugNumPlayers:Int) {
		
		game = __game;
		div = __div;
		debugNumPlayers = __debugNumPlayers;
		
		canvas = new Canvas(div, 400, 300);
		stage = new Stage(canvas.tag);
		scene = new Container();
		stage.addChild(scene);
		
		initialize();
	}
	
	private function initialize():Void {
				
		// build the scene
		background = GUIFactory.drawSolidRect(new Shape(), 0x0, 1, 0, 0, 800, 600);
		
		grid = new GameGrid();
		//for (ike in 0...Common.MAX_PLAYERS) grid.makePlayerHeadAndBody(Common.TEAM_COLORS[ike]);
		well = new Well();
		timerPanel = new TimerPanel();
		statPanel = new StatPanel(Layout.STAT_PANEL_HEIGHT);
		barBackground = GUIFactory.drawSolidRect(new Shape(), 0x222222, 1, 0, 0, Layout.BAR_WIDTH * 0.6, Layout.BAR_HEIGHT);
		bar = GUIFactory.makeContainer([barBackground, timerPanel, statPanel, well]);
		
		GUIFactory.fillContainer(scene, [background, grid, bar]);
		
		well.rotateHint = rotateHint;
		well.rotatePiece = rotatePiece;
		well.biteHint = biteHint;
		well.toggleBite = toggleBite;
		well.swapHint = swapHint;
		well.swapPiece = swapPiece;

		timerPanel.skipFunc = skipTurn;
		
		//box = new Rectangle(0, 0, Common.BOARD_SIZE * Layout.UNIT_SIZE, Common.BOARD_SIZE * Layout.UNIT_SIZE);
		//box.inflate(Layout.UNIT_SIZE * 1.5, Layout.UNIT_SIZE * 1.5);

		// position things
		well.x = well.y = Layout.BAR_MARGIN;
		timerPanel.x = Layout.BAR_MARGIN;
		timerPanel.y = well.y + Layout.WELL_WIDTH + Layout.BAR_MARGIN;
		statPanel.x = Layout.BAR_MARGIN;
		statPanel.y = timerPanel.y + Layout.TIMER_HEIGHT + Layout.BAR_MARGIN;
		
		div.onmouseup = mouseHandler;
		Lib.document.onkeydown = Lib.document.onkeyup = keyHandler;
		Lib.window.onresize = resize;
		resize(null);
	}
	
	private function resize(event:Event):Void {
		if (!canvas.resize()) return;
		
		var sw:Float = Math.max(canvas.width, MIN_WIDTH);
		var sh:Float = Math.max(canvas.height, MIN_HEIGHT);
		
		// size the background. This is more important later when I texture it
		background.scaleX = background.scaleY = 1;
		
		if (800 / 600 < sw / sh) {
			background.scaleY = background.scaleX = sw / 800;
		} else {
			background.scaleX = background.scaleY = sh / 600;
		}
		
		bar.scaleX = bar.scaleY = sh / Layout.BAR_HEIGHT;
		bar.x = 0;
		bar.y = 0;
		var barWidth:Float = Layout.BAR_WIDTH * bar.scaleX;
		grid.scaleY = grid.scaleX = (((sw - barWidth < sh) ? sw - barWidth : sh) - Layout.GRID_MARGIN * 2) / (Common.BOARD_SIZE * Layout.UNIT_SIZE + 20);
		var gridWidth:Float = (Common.BOARD_SIZE * Layout.UNIT_SIZE + 20) * grid.scaleX;
		grid.x = barWidth + (sw - barWidth - gridWidth) * 0.5;
		grid.y = (sh - gridWidth) * 0.5;
		
		stage.tick();
	}
	
	private function keyHandler(event:Event):Void {
		
	}
	
	private function mouseHandler(event:Event):Void {
		
	}
	
	private function rotateHint(cc:Bool, over:Bool):Void;
	private function rotatePiece(?cc:Bool):Void;
	private function biteHint(over:Bool):Void;
	private function toggleBite():Void;
	private function swapHint(over:Bool):Void;
	private function swapPiece():Void;
	private function skipTurn():Void;
}