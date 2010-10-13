package net.rezmason.scourge;

import flash.display.BitmapData;
import flash.display.BitmapDataChannel;
import flash.display.BlendMode;
import flash.display.CapsStyle;
import flash.display.GradientType;
import flash.display.JointStyle;
import flash.display.LineScaleMode;
import flash.display.MovieClip;
import flash.display.Shape;
import flash.display.SimpleButton;
import flash.display.Sprite;
import flash.display.Stage;
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.events.TimerEvent;
import flash.filters.BlurFilter;
import flash.filters.DisplacementMapFilter;
import flash.filters.DisplacementMapFilterMode;
import flash.filters.GlowFilter;
import flash.geom.ColorTransform;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.text.TextField;
import flash.utils.Timer;
import flash.ui.Keyboard;
import flash.ui.Mouse;
import flash.Vector;

import net.kawa.tween.KTween;
import net.kawa.tween.KTJob;
import net.kawa.tween.easing.Quad;
import net.kawa.tween.easing.Linear;
import net.kawa.tween.easing.Elastic;

import flash.Lib;

import net.rezmason.display.Grid;

class Board {
	
	inline static var UNIT_SIZE:Int = 20;
	inline static var BOARD_WIDTH:Int = Common.BOARD_SIZE * UNIT_SIZE;
	inline static var BOARD_BORDER:Int = 10;
	inline static var MIN_WIDTH:Int = 400;
	inline static var MIN_HEIGHT:Int = 300;
	inline static var SNAP_RATE:Float = 0.3;
	inline static var QUICK:Float = 0.1;
	
	inline static var POUNCE:Dynamic = Quad.easeOut;
	inline static var ZIGZAG:Dynamic = Elastic.easeOut;
	
	private static var SLIME_FILTER:GlowFilter = new GlowFilter(0x0, 1, 14, 14, 2, 1, true);
	private static var GLOW_FILTER:GlowFilter = new GlowFilter(0xFFFFFF, 1, 7, 7, 20, 1, true);
	private static var GLOW_FILTER_2:GlowFilter = new GlowFilter(0xFFFFFF, 1, 10, 10, 20, 1, true);
	private static var BLUR_FILTER:BlurFilter = new BlurFilter(6, 6, 2);
	private static var PLAIN_CT:ColorTransform = GUIFactory.makeCT(0xFFFFFF);
	private static var TEAM_COLORS:Array<ColorTransform> = [
		GUIFactory.makeCT(0xFF0090), 
		GUIFactory.makeCT(0xFFD000), 
		GUIFactory.makeCT(0x60FF00), 
		GUIFactory.makeCT(0x0090FF)
	];
	private static var ORIGIN:Point = new Point();
	
	private var game:Game;
	private var scene:Sprite;
	private var stage:Stage;
	
	private var cursor:Sprite;
	private var pointer:Sprite;
	private var currentPlayerIndex:Int;
	private var background:Shape;
	private var grid:Sprite;
	private var gridBackground:Shape;
	private var gridPattern:Grid;
	private var gridBiteRegion:Shape;
	private var clouds:Shape;
	private var gridTeams:Sprite;
	private var gridHeads:Sprite;
	private var piece:Sprite;
	private var teamBodies:Array<Shape>;
	private var teamHeads:Array<Shape>;
	private var teamBitmaps:Array<BitmapData>;
	private var placeX:Int;
	private var placeY:Int;
	private var keyList:Array<Bool>;
	private var pieceRecipe:Array<Int>;
	private var pieceCenter:Array<Float>;
	private var pieceContainer:Sprite;
	
	private var traceBox:TextField;
	
	public function new(__game:Game, __scene:Sprite) {
		scene = __scene;
		game = __game;
		
		keyList = [];
		
		if (scene.stage != null) {
			connectToStage();
		} else {
			scene.addEventListener(Event.ADDED_TO_STAGE, connectToStage);
		}
	}
	
	private function connectToStage(?event:Event):Void {
		scene.removeEventListener(Event.ADDED_TO_STAGE, connectToStage);
		stage = scene.stage;
		stage.focus = stage;
		
		initialize();
	}
	
	private function initialize():Void {
		
		background = GUIFactory.drawSolidRect(new Shape(), 0x0, 1, 0, 0, 800, 600);
		gridBackground = GUIFactory.drawSolidRect(new Shape(), 0x777777, 1, 0, 0, BOARD_WIDTH + 20, BOARD_WIDTH + 20, 8);
		GUIFactory.drawSolidRect(gridBackground, 0x0, 1, 6, 6, BOARD_WIDTH + 8, BOARD_WIDTH + 8, 4);
		gridBiteRegion = new Shape();
		gridTeams = new Sprite();
		gridTeams.transform.colorTransform = new ColorTransform(0.6, 0.6, 0.6, 3);
		gridTeams.blendMode = BlendMode.ADD;
		gridHeads = new Sprite();
		gridHeads.x = gridHeads.y = 10;
		gridPattern = new Grid(UNIT_SIZE * 2, BOARD_WIDTH, BOARD_WIDTH, 0xFF111111, 0xFF222222);
		gridPattern.x = gridPattern.y = 10;
		var cloudCover:BitmapData = new BitmapData(BOARD_WIDTH, BOARD_WIDTH, false, 0xFF000000);
		cloudCover.perlinNoise(30, 30, 3, Std.int(Math.random() * 0xFF), false, true, 7, true);
		clouds = GUIFactory.makeBitmapShape(cloudCover, 1, true);
		clouds.x = clouds.y = 10;
		clouds.blendMode = BlendMode.OVERLAY;
		grid = GUIFactory.makeContainer([gridBackground, gridPattern, gridTeams, gridHeads, clouds]);
		grid.cacheAsBitmap = true;
		traceBox = GUIFactory.makeTraceBox();
		
		piece = new Sprite();
		piece.filters = [GLOW_FILTER];
		pieceContainer = GUIFactory.makeContainer([piece]);
		pointer = GUIFactory.makePointer();
		cursor = GUIFactory.makeContainer([pieceContainer, pointer]);
		cursor.mouseEnabled = cursor.mouseChildren = false;
		
		scene.addChild(background);
		scene.addChild(grid);
		scene.addChild(traceBox); // for now
		scene.addChild(cursor);
		
		// The grid also contains blown up transparent bitmaps, 
		// tinted and inner-glow-filtered with the team colors
		
		teamHeads = [];
		teamBodies = [];
		teamBitmaps = [];
		
		var bmp:BitmapData;
		var shp:Shape;
		for (ike in 0...Common.MAX_PLAYERS) {
			bmp = new BitmapData(BOARD_WIDTH + 2 * BOARD_BORDER, BOARD_WIDTH + 2 * BOARD_BORDER, true, 0x0);
			teamBitmaps.push(bmp);
			shp = GUIFactory.makeBitmapShape(bmp);
			shp.x = (grid.width  - shp.width ) / 2;
			shp.y = (grid.height - shp.height) / 2;
			gridTeams.addChild(shp);
			teamBodies.push(shp);
			shp.transform.colorTransform = TEAM_COLORS[ike];
		}
		
		var head:Shape;
		for (ike in 0...Common.MAX_PLAYERS) {
			head = GUIFactory.makeHead(UNIT_SIZE);
			gridHeads.addChild(head);
			teamHeads.push(head);
			head.transform.colorTransform = TEAM_COLORS[ike];
		}
		
		stage.addEventListener(Event.ADDED, resize, true);
		stage.addEventListener(Event.RESIZE, resize);
		stage.addEventListener(KeyboardEvent.KEY_DOWN, keyHandler);
		stage.addEventListener(KeyboardEvent.KEY_UP, keyHandler);
		stage.addEventListener(MouseEvent.MOUSE_MOVE, moveCursor);
		Mouse.hide();
		
		game.begin(4);
		currentPlayerIndex = game.getCurrentPlayerIndex();
		update(true, true);
		createHeads();
		//fillBoardRandomly();
	}
	
	private function resize(?event:Event):Void {
		
		if (event.type == Event.ADDED && event.target != flash.Lib.current) return;
		
		var sw:Float = stage.stageWidth;
		var sh:Float = stage.stageHeight;
		
		sw = Math.max(sw, MIN_WIDTH);
		sh = Math.max(sh, MIN_HEIGHT);
		
		// resize background
		
		background.scaleX = background.scaleY = 1;
		if (background.width / background.height < sw / sh) {
			background.width = sw;
			background.scaleY = background.scaleX;
		} else {
			background.height = sh;
			background.scaleX = background.scaleY;
		}
		
		// scale and reposition grid
		if (sw > sh) {
			grid.width = sh - 20;
			grid.scaleY = grid.scaleX;
		} else {
			grid.height = sw - 20;
			grid.scaleX = grid.scaleY;
		}
		grid.x = (sw - grid.width ) * 0.5;
		grid.y = (sh - grid.height) * 0.5;
		piece.scaleX = piece.scaleY = grid.scaleX;
	}
	
	private function update(?thePiece:Bool, ?thePlay:Bool):Void {
		if (thePlay) {
			updateGrid();
			updateHeads();
		}
		
		if (thePiece) {
			updatePiece();
			showPiece();
		}
	}
	
	private function updateHeads():Void {
		var numPlayers:Int = game.getNumPlayers();
		for (ike in 0...numPlayers) {
			var head:Shape = teamHeads[ike];
			if (head.alpha == 1 && !game.isPlayerAlive(ike)) {
				KTween.to(head, QUICK * 5, {scaleX:1, scaleY:1, alpha:0}, Linear.easeOut);
			}
		}
	}
	
	private function updatePiece(?previousAngle:Int = 0):Void {
		
		// get the current mouse offsets;
		
		var c1X:Float = 0;
		var c1Y:Float = 0;
		var offX:Float = 0;
		var offY:Float = 0;
		
		if (pieceCenter != null) {
			
			c1X = UNIT_SIZE * pieceCenter[0];
			c1Y = UNIT_SIZE * pieceCenter[1];
			
			offX = piece.mouseX - c1X;
			offY = piece.mouseY - c1Y;
			
			if (previousAngle > 0) {
				offX *= -1;
			} else if (previousAngle < 0) {
				offY *= -1;
			}
		}
		
		pieceRecipe = game.getPiece();
		pieceCenter = game.getPieceCenter();
		
		var c2X:Float = UNIT_SIZE * pieceCenter[0];
		var c2Y:Float = UNIT_SIZE * pieceCenter[1];
		
		// redraw the piece
		piece.graphics.clear();
	
		var bW:Float = UNIT_SIZE;
		var bC:Float = bW * 0.4;
	
		piece.graphics.beginFill(0xFF222222);
	
		var ike:Int = 0;
		while (ike < pieceRecipe.length) {
			piece.graphics.drawRoundRect(pieceRecipe[ike] * bW, pieceRecipe[ike + 1] * bW, bW, bW, bC, bC);
			ike += 2;
		}
		
		ike = pieceRecipe.length - 2;
		
		piece.graphics.endFill();
	
		if (pieceRecipe == Pieces.O_BLOCK) {
			piece.graphics.beginFill(0xFF222222);
			piece.graphics.drawRect(0.5 * bW, 0.5 * bW, bW, bW);
			piece.graphics.endFill();
		}
		
		piece.x = 0;
		piece.y = 0;
		//piece.x = (piece.mouseX - c2X + offY) * piece.scaleX;
		//piece.y = (piece.mouseY - c2Y + offX) * piece.scaleY;
		dragPiece(true);
	}
	
	private function updateGrid():Void {
		var gameGrid:Vector<UInt> = game.getGrid();
		var len:Int = Common.BOARD_NUM_CELLS;
		var rect:Rectangle = new Rectangle(0, 0, UNIT_SIZE, UNIT_SIZE);
		var rx:Int, ry:Int;
		
		prepareTeamBitmaps();
		
		for (ike in 0...len) {
			if (gameGrid[ike] > 0) {
				rx = ike % Common.BOARD_SIZE;
				ry = Std.int((ike - rx) / Common.BOARD_SIZE);
				rect.x = rx * UNIT_SIZE + BOARD_BORDER;
				rect.y = ry * UNIT_SIZE + BOARD_BORDER;
				teamBitmaps[gameGrid[ike] - 1].fillRect(rect, 0xFFFFFFFF);
			}
		}
		
		finishTeamBitmaps();
	}
	
	private function createHeads():Void {
		var heads:Array<Int> = Common.HEADS[game.getNumPlayers() - 1];
		
		for (ike in 0...Common.MAX_PLAYERS) {
			var head:Shape = teamHeads[ike];
			if (ike * 2 < heads.length) {
				head.visible = true;
				head.alpha = 1;
				head.x = (heads[ike * 2    ] + 0.5) * UNIT_SIZE;
				head.y = (heads[ike * 2 + 1] + 0.5) * UNIT_SIZE;
			} else {
				head.visible = false;
			}
		}
	}
	
	private function prepareTeamBitmaps():Void {
		for (ike in 0...Common.MAX_PLAYERS) teamBitmaps[ike].fillRect(teamBitmaps[ike].rect, 0x0);
	}
	
	private function finishTeamBitmaps():Void {
		var bmp:BitmapData;
		var bmp2:BitmapData = new BitmapData(BOARD_WIDTH + 2 * BOARD_BORDER, BOARD_WIDTH + 2 * BOARD_BORDER, true, 0x0);
		
		for (ike in 0...Common.MAX_PLAYERS) {
			bmp = teamBitmaps[ike];
			
			bmp.applyFilter(bmp, bmp.rect, bmp.rect.topLeft, SLIME_FILTER);
			bmp2.fillRect(bmp.rect, 0x0);
			bmp2.draw(bmp);
			
			bmp.fillRect(bmp.rect, 0xFFFFFFFF);
			bmp.copyChannel(bmp2, bmp.rect, bmp.rect.topLeft, BitmapDataChannel.RED, BitmapDataChannel.ALPHA);
			bmp.applyFilter(bmp, bmp.rect, bmp.rect.topLeft, BLUR_FILTER);
		}
	}
	
	private function fillBoardRandomly(?event:Event):Void {
		var bmp:BitmapData;
		var whatev:Array<Array<Null<Bool>>> = [];
		var rect:Rectangle = new Rectangle();
		
		prepareTeamBitmaps();
		
		for (ike in 0...Common.MAX_PLAYERS) {
			bmp = teamBitmaps[ike];
			
			for (jen in 0...80) {
				var rx:Int = 0;
				var ry:Int = 0;
				while (true) {
					rx = Std.int(Math.random() * Common.BOARD_SIZE) * UNIT_SIZE;
					ry = Std.int(Math.random() * Common.BOARD_SIZE) * UNIT_SIZE;
					if (whatev[ry] == null) {
						whatev[ry] = [];
					}
					if (whatev[ry][rx] == null) {
						whatev[ry][rx] = true;
						break;
					}
				}	
				rect.x = rx + BOARD_BORDER;
				rect.y = ry + BOARD_BORDER;
				rect.width = rect.height = UNIT_SIZE;
				bmp.fillRect(rect, 0xFFFFFFFF);
			}
		}
		
		finishTeamBitmaps();
	}
	
	private function moveCursor(?event:Event):Void {
		cursor.x = stage.mouseX;
		cursor.y = stage.mouseY;
	}
	
	private function liftPiece(event:Event):Void {
		/*
		if (draggingPiece) return;
		
		draggingPiece = true;
		pieceHandle.mouseEnabled = pieceHandle.mouseChildren = false;
		stage.addEventListener(MouseEvent.MOUSE_MOVE, dragPieceOnEvent);
		
		if (pieceHandleJob != null) pieceHandleJob.close();
		if (pieceJob != null) pieceJob.close();
		if (pieceHandleSpinJob != null) pieceHandleSpinJob.complete();
		
		pieceBoardScale = gridPattern.transform.concatenatedMatrix.a / piece.transform.concatenatedMatrix.a;
		
		popPiece(true);
			
		if (event.currentTarget == grid) {
			pieceHandle.scaleX = pieceHandle.scaleY = pieceBoardScale;
		} else {
			pieceHandleJob = KTween.to(pieceHandle, QUICK, {scaleX:1.2, scaleY:1.2}, Linear.easeOut);
			piece.x -= well.mouseX - pieceHandle.x;
			piece.y -= well.mouseY - pieceHandle.y;
		}
		
		dragPiece();
		*/
	}
	
	private function dragPiece(?snap:Bool):Void {
		/*
		if (!draggingPiece) return;
		
		var oldX:Float = pieceHandle.x;
		var oldY:Float = pieceHandle.y;
		
		var overGrid:Bool = gridBox.contains(gridPattern.mouseX, gridPattern.mouseY);
		var scale:Float;
		
		if (overGrid != pieceScaledDown) {
			pieceScaledDown = overGrid;
			if (pieceHandleJob != null) pieceHandleJob.abort();
			scale = overGrid ? pieceBoardScale : 1.4;
			pieceHandleJob = KTween.to(pieceHandle, QUICK, {scaleX:scale, scaleY:scale}, Linear.easeOut, dragPieceOnEvent);
		}
		
		pieceHandle.x = well.mouseX;
		pieceHandle.y = well.mouseY;
		well.addChild(pieceHandle);
			
		if (pieceHandle.scaleX == pieceBoardScale && overGrid && gridBox.containsRect(pieceHandle.getBounds(gridPattern))) {
			
			// grid snapping.
			
			var gp:Point = gridPattern.globalToLocal(piece.localToGlobal(ORIGIN));
			
			placeX = Std.int(Math.round(gp.x / UNIT_SIZE));
			placeY = Std.int(Math.round(gp.y / UNIT_SIZE));
			
			if (game.evaluatePosition(placeX, placeY)) {
				pieceHandle.transform.colorTransform = PLAIN_CT;
			} else {
				pieceHandle.transform.colorTransform = TEAM_COLORS[currentPlayerIndex];
			}
			
			var gp2:Point = new Point(placeX * UNIT_SIZE, placeY * UNIT_SIZE);
			
			gp  = pieceHandle.globalToLocal(gridPattern.localToGlobal(gp));
			gp2 = pieceHandle.globalToLocal(gridPattern.localToGlobal(gp2));
			
			gp2.x -= gp.x;
			gp2.y -= gp.y;
			
			pieceHandle.x = Std.int(pieceHandle.x + gp2.x * pieceHandle.scaleX);
			pieceHandle.y = Std.int(pieceHandle.y + gp2.y * pieceHandle.scaleY);
			
			if (pieceHandle.x == handleGoalX && pieceHandle.y == handleGoalY) {
				if (handlePushTimer.running) {
					pieceHandle.x = oldX;
					pieceHandle.y = oldY;
				}
			} else if (snap) {
				handleGoalX = pieceHandle.x;
				handleGoalY = pieceHandle.y;
				pieceHandle.x = oldX;
				pieceHandle.y = oldY;
				handlePushTimer.start();
			}
			
		} else {
			placeX = placeY = -1;
			traceBox.text = "";
			handlePushTimer.reset();
		}
		*/
	}
	
	private function dropPiece(?event:Event):Void {
		/*
		if (!draggingPiece) return;
		pieceHandle.x = handleGoalX;
		pieceHandle.y = handleGoalY;
		handlePushTimer.stop();
		
		dragPiece();
		
		pieceHandle.transform.colorTransform = TEAM_COLORS[currentPlayerIndex];
		piece.filters = [GLOW_FILTER];
		pieceScaledDown = false;
		if (pieceHandleJob != null) pieceHandleJob.close();
		if (pieceJob != null) pieceJob.close();
		
		draggingPiece = false;
		
		if (placeX != -1 && game.processPlayerAction(PlayerAction.PLACE_PIECE(placeX, placeY))) {
			currentPlayerIndex = game.getCurrentPlayerIndex();
			update(true, true);
		} else {
			pieceHandleJob = KTween.to(pieceHandle, 2 * QUICK, {x:wellBackground.width / 2, y:wellBackground.height / 2, scaleX:1, scaleY:1}, POUNCE, enableDrag);
			pieceJob = KTween.to(piece, 2 * QUICK, {x:pieceHomeX, y:pieceHomeY}, POUNCE);
			well.addChild(pieceHandle);
		}
		
		scene.removeEventListener(MouseEvent.MOUSE_MOVE, dropPiece);
		*/
	}
	
	private function showPiece():Void {
		/*
		well.addChildAt(pieceHandle, 1);
		piece.x = pieceHomeX;
		piece.y = pieceHomeY;
		pieceHandle.x = wellBackground.width  / 2;
		pieceHandle.y = wellBackground.height / 2;
		pieceHandle.scaleX = pieceHandle.scaleY = 0.7;
		pieceHandle.alpha = 0;
		pieceHandle.mouseEnabled = pieceHandle.mouseChildren = false;
		if (pieceHandleJob != null) pieceHandleJob.close();
		if (pieceHandleSpinJob != null) pieceHandleSpinJob.complete();
		pieceHandleJob = KTween.to(pieceHandle, 3 * QUICK, {alpha:1, scaleX:1, scaleY:1}, POUNCE, enableDrag);
		*/
	}
	
	private function rotatePiece(?event:Event):Void {
		/*
		if (pieceHandleSpinJob != null) pieceHandleSpinJob.complete();
		var cc:Bool = event != null && event.currentTarget == rotateLeftButton;
		game.processPlayerAction(PlayerAction.SPIN_PIECE(cc));
		var angle:Int = cc ? -90 : 90;
		updatePiece(angle);
		pieceHandleSpinJob = KTween.from(pieceHandle, 2 * QUICK, {rotation:-angle}, POUNCE, enableDrag);
		pieceHandle.mouseEnabled = pieceHandle.mouseChildren = false;
		*/
	}
	
	private function keyHandler(event:KeyboardEvent):Void {
		var down:Bool = event.type == KeyboardEvent.KEY_DOWN;
		var wasDown:Bool = keyList[event.keyCode];
		if (down != wasDown) {
			switch (event.keyCode) {
				case Keyboard.SPACE: if (down) rotatePiece();
				case Keyboard.SHIFT: down ? startBite() : endBite();
				case Keyboard.TAB: if (down) swapPiece();
				case Keyboard.ESCAPE: if (down) skipTurn();
			}
		}
		keyList[event.keyCode] = (event.type == KeyboardEvent.KEY_DOWN);
	}
	
	private function toggleBite(?event:Event):Void {
		
	}
	
	private function startBite(?event:Event):Void {
		//game.processPlayerAction(PlayerAction.START_BITE(x, y));
	}
	
	private function endBite(?event:Event):Void {
		//game.processPlayerAction(PlayerAction.END_BITE(x, y));
	}
	
	private function swapPiece(?event:Event):Void {
		/*
		if (draggingPiece) {
			placeX = placeY = -1;
			dropPiece();
		}
		if (game.processPlayerAction(PlayerAction.SWAP_PIECE)) update(true);
		*/
	}
	
	private function skipTurn(?event:Event):Void {
		game.processPlayerAction(PlayerAction.SKIP);
		currentPlayerIndex = game.getCurrentPlayerIndex();
		update(true);
	}
}