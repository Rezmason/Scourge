package net.rezmason.scourge;

import flash.display.BitmapData;
import flash.display.BitmapDataChannel;
import flash.display.BlendMode;
import flash.display.CapsStyle;
import flash.display.LineScaleMode;
import flash.display.Shape;
import flash.display.SimpleButton;
import flash.display.Sprite;
import flash.display.Stage;
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.events.TimerEvent;
import flash.filters.BlurFilter;
import flash.filters.GlowFilter;
import flash.geom.ColorTransform;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;
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

import flash.text.TextField;
import flash.text.TextFormat;

class Board {
	
	inline static var __snap:Bool = true; // not sure if I want this
	
	inline static var UNIT_SIZE:Int = 20;
	inline static var BOARD_WIDTH:Int = Common.BOARD_SIZE * UNIT_SIZE;
	inline static var BAR_WIDTH:Int = 250;
	inline static var BAR_HEIGHT:Int = 600;
	inline static var BAR_MARGIN:Int = 20;
	inline static var WELL_WIDTH:Int = 210;
	inline static var WELL_BORDER:Int = 10;
	inline static var BOARD_BORDER:Int = 10;
	inline static var MIN_WIDTH:Int = 400;
	inline static var MIN_HEIGHT:Int = 300;
	inline static var SNAP_RATE:Float = 0.3;
	inline static var QUICK:Float = 0.1;
	
	inline static var POUNCE:Float -> Float = Quad.easeOut;
	inline static var ZIGZAG:Float -> Float = Elastic.easeOut;
	
	private static var SLIME_FILTER:GlowFilter = new GlowFilter(0x0, 1, 14, 14, 2.5, 1, true);
	private static var GLOW_FILTER:GlowFilter = new GlowFilter(0xFFFFFF, 1, 7, 7, 20, 1, true);
	private static var GLOW_FILTER_2:GlowFilter = new GlowFilter(0xFFFFFF, 1, 10, 10, 20, 1, true);
	private static var BITE_GLOW:GlowFilter = new GlowFilter(0xFFFFFF, 1, 7, 7, 20, 1, true);
	private static var TOOTH_GLOW:GlowFilter = new GlowFilter(0xFFFFFF, 1, 7, 7, 1);
	private static var BLUR_FILTER:BlurFilter = new BlurFilter(6, 6, 2);
	private static var GRID_BLUR:BlurFilter = new BlurFilter(4, 4, 1);
	private static var SWAP_FILTER:GlowFilter = new GlowFilter(0xFFFFFF, 1, 10, 10, 8, 1);
	private static var BITE_MASK_BLUR:BlurFilter = new BlurFilter(3, 3, 10);
	private static var PLAIN_CT:ColorTransform = GUIFactory.makeCT(0xFFFFFF);
	private static var WHITE_CT:ColorTransform = new ColorTransform(1, 1, 1, 1, 0xFF, 0xFF, 0xFF);
	private static var TEAM_COLORS:Array<Int> = [0xFF0090, 0xFFC800, 0x60FF00, 0x0090FF];
	private static var ORIGIN:Point = new Point();
	
	private var game:Game;
	private var scene:Sprite;
	private var stage:Stage;
	private var teamCTs:Array<ColorTransform>;
	private var currentPlayer:Player;
	private var currentPlayerIndex:Int;
	private var shiftBite:Bool;
	private var background:Shape;
	private var grid:Sprite;
	private var gridBackground:Shape;
	private var gridPattern:Grid;
	private var gridBlurredPatternData:BitmapData;
	private var gridBlurredPattern:Shape;
	private var gridBiteRegion:Shape;
	private var clouds:Shape;
	private var gridTeams:Sprite;
	private var gridHeads:Sprite;
	private var bar:Sprite;
	private var toothContainer:Sprite;
	private var biteTooth:Sprite;
	private var bt1:Sprite;
	private var bBody:Shape;
	private var bt2:Sprite;
	private var barBackground:Shape;
	private var well:Sprite;
	private var somethingElse:Sprite;
	private var wellBackground:Shape;
	private var rotateLeftButton:SimpleButton;
	private var rotateRightButton:SimpleButton;
	private var biteButton:SimpleButton;
	private var swapButton:SimpleButton;
	private var piece:Sprite;
	private var pieceBlocks:Array<Shape>;
	private var piecePlug:Shape;
	private var pieceBite:Sprite;
	private var pieceHandle:Sprite;
	private var teamBodies:Array<Shape>;
	private var teamHeads:Array<Shape>;
	private var teamBitmaps:Array<BitmapData>;
	private var draggingPiece:Bool;
	private var biting:Bool;
	private var draggingBite:Bool;
	private var swapHinting:Bool;
	private var gridBox:Rectangle;
	private var pieceBoardScale:Float;
	private var pieceScaledDown:Bool;
	private var placeX:Int;
	private var placeY:Int;
	private var handleGoalX:Float;
	private var handleGoalY:Float;
	private var handlePushTimer:Timer;
	private var keyList:Array<Bool>;
	private var biteLimits:Array<Int>;
	
	private var pieceRecipe:Array<Int>;
	private var pieceCenter:Array<Float>;
	
	private var traceBox:TextField;
	
	private var pieceHandleJob:KTJob;
	private var pieceHandleSpinJob:KTJob;
	private var pieceJob:KTJob;
	private var guiColorJob:KTJob;
	private var guiColorTransform:ColorTransform;
	private var pieceBlockJobs:Array<KTJob>;
	private var pieceBiteJob:KTJob;
	private var toothContainerJob:KTJob;
	private var biteToothJob:KTJob;
	
	private var currentBlockForSwapHint:Int;
	
	private var pieceHomeX:Float;
	private var pieceHomeY:Float;
	
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
		
		draggingPiece = false;
		pieceScaledDown = false;
		biting = false;
		draggingBite = false;
		swapHinting = false;
		teamHeads = [];
		teamBodies = [];
		teamBitmaps = [];
		pieceBlockJobs = [];
		guiColorTransform = new ColorTransform();
		
		teamCTs = [];
		for (ike in 0...TEAM_COLORS.length) teamCTs[ike] = GUIFactory.makeCT(TEAM_COLORS[ike]);
		
		var bmp:BitmapData;
		var shp:Shape;
		for (ike in 0...Common.MAX_PLAYERS) {
			
			bmp = new BitmapData(BOARD_WIDTH + 2 * BOARD_BORDER, BOARD_WIDTH + 2 * BOARD_BORDER, true, 0x0);
			teamBitmaps.push(bmp);
			
			teamBodies.push(GUIFactory.makeBitmapShape(bmp, 1, true, teamCTs[ike]));
			teamHeads.push(GUIFactory.makeHead(UNIT_SIZE, teamCTs[ike]));
		}
		
		background = GUIFactory.drawSolidRect(new Shape(), 0x0, 1, 0, 0, 800, 600);
		gridBackground = GUIFactory.drawSolidRect(new Shape(), 0x333333, 1, 0, 0, BOARD_WIDTH + 20, BOARD_WIDTH + 20, 8);
		GUIFactory.drawSolidRect(gridBackground, 0x0, 1, 6, 6, BOARD_WIDTH + 8, BOARD_WIDTH + 8, 4);
		gridBiteRegion = new Shape();
		gridTeams = GUIFactory.makeContainer(teamBodies.copy());
		gridTeams.transform.colorTransform = new ColorTransform(0.6, 0.6, 0.6, 3);
		gridTeams.blendMode = BlendMode.ADD;
		gridHeads = GUIFactory.makeContainer(teamHeads.copy());
		gridHeads.x = gridHeads.y = BOARD_BORDER;
		gridPattern = new Grid(UNIT_SIZE * 2, BOARD_WIDTH, BOARD_WIDTH, 0xFF111111, 0xFF222222);
		gridPattern.x = gridPattern.y = BOARD_BORDER;
		gridBlurredPatternData = new BitmapData(BOARD_WIDTH, BOARD_WIDTH, true, 0x0);
		gridBlurredPattern = GUIFactory.makeBitmapShape(gridBlurredPatternData, 1, true);
		gridBlurredPattern.x = gridBlurredPattern.y = gridPattern.x;
		var cloudCover:BitmapData = new BitmapData(BOARD_WIDTH, BOARD_WIDTH, false, 0xFF000000);
		cloudCover.perlinNoise(30, 30, 3, Std.int(Math.random() * 0xFF), false, true, 7, true);
		var cloudAmount:Float = 0.7;
		cloudCover.colorTransform(cloudCover.rect, new ColorTransform(cloudAmount, cloudAmount, cloudAmount));
		clouds = GUIFactory.makeBitmapShape(cloudCover, 1, true);
		clouds.x = clouds.y = BOARD_BORDER;
		clouds.blendMode = BlendMode.OVERLAY;
		toothContainer = new Sprite();
		toothContainer.visible = false;
		toothContainer.mouseEnabled = toothContainer.mouseChildren = false;
		toothContainer.alpha = 0;
		toothContainer.filters = [BITE_GLOW];
		toothContainer.x = toothContainer.y = BOARD_BORDER;
		bt1 = GUIFactory.makeTooth(UNIT_SIZE * 1.2);
		bBody = new Shape();
		bt2 = GUIFactory.makeTooth(UNIT_SIZE * 1.2);
		biteTooth = GUIFactory.makeContainer([bt1, bBody, bt2]);
		biteTooth.filters = [TOOTH_GLOW];
		biteTooth.visible = false;
		biteTooth.mouseEnabled = biteTooth.mouseChildren = false;
		biteTooth.transform.colorTransform = WHITE_CT;
		biteTooth.filters = [TOOTH_GLOW];
		grid = GUIFactory.makeContainer([gridBackground, gridPattern, gridBlurredPattern, gridTeams, toothContainer, gridHeads, clouds, biteTooth]);
		grid.cacheAsBitmap = true;
		grid.tabEnabled = !(grid.buttonMode = grid.useHandCursor = true);
		gridBox = gridPattern.getBounds(gridPattern);
		gridBox.inflate(UNIT_SIZE * 1.5, UNIT_SIZE * 1.5);
		traceBox = GUIFactory.makeTraceBox(400);
		
		wellBackground = GUIFactory.drawSolidRect(new Shape(), 0x222222, 1, 0, 0, WELL_WIDTH, WELL_WIDTH, 60);
		
		rotateLeftButton = GUIFactory.makeButton(ScourgeLib_RotateSymbol, ScourgeLib_WellButtonHitState, 1.5, 0, true);
		rotateRightButton = GUIFactory.makeButton(ScourgeLib_RotateSymbol, ScourgeLib_WellButtonHitState, 1.5, 90);
		biteButton = GUIFactory.makeButton(ScourgeLib_BiteSymbol, ScourgeLib_WellButtonHitState, 1.5, 180);
		swapButton = GUIFactory.makeButton(ScourgeLib_SwapSymbol, ScourgeLib_WellButtonHitState, 1.5);
		
		rotateLeftButton.y = wellBackground.height - WELL_BORDER;
		rotateLeftButton.x = WELL_BORDER;
		rotateRightButton.y = WELL_BORDER;
		rotateRightButton.x = wellBackground.width - WELL_BORDER;
		swapButton.x = WELL_BORDER;
		swapButton.y = WELL_BORDER;
		biteButton.x = wellBackground.height - WELL_BORDER;
		biteButton.y = wellBackground.width - WELL_BORDER;
		
		GUIFactory.wireUp(rotateLeftButton, rotateHint, rotateHint, rotatePiece);
		GUIFactory.wireUp(rotateRightButton, rotateHint, rotateHint, rotatePiece);
		GUIFactory.wireUp(biteButton, biteHint, biteHint, toggleBite);
		GUIFactory.wireUp(swapButton, swapHint, swapHint, swapPiece);
		
		well = GUIFactory.makeContainer([wellBackground, rotateLeftButton, rotateRightButton, swapButton, biteButton]);
		somethingElse = GUIFactory.drawSolidRect(new Sprite(), 0x111111, 1, 0, 0, 210, BAR_HEIGHT - 3 * BAR_MARGIN - WELL_WIDTH, 60);
		barBackground = GUIFactory.drawSolidRect(new Shape(), 0x777777, 1, 150, 0, BAR_WIDTH - 150, BAR_HEIGHT);
		bar = GUIFactory.makeContainer([barBackground, well, somethingElse]);
		
		well.x = well.y = BAR_MARGIN;
		somethingElse.x = 20;
		somethingElse.y = well.y + WELL_WIDTH + BAR_MARGIN;
		
		scene.addChild(background);
		scene.addChild(grid);
		scene.addChild(bar);
		scene.addChild(traceBox);
		
		pieceBlocks = [];
		var bW:Int = UNIT_SIZE + 2;
		for (ike in 0...Common.MOST_BLOCKS_IN_PIECE + 1) pieceBlocks.push(GUIFactory.drawSolidRect(new Shape(), 0x222222, 1, -1, -1, bW, bW, bW * 0.5));
		piece = GUIFactory.makeContainer(pieceBlocks.copy());
		piecePlug = GUIFactory.drawSolidRect(new Shape(), 0x222222, 1, 0, 0, bW, bW, bW);
		piecePlug.visible = false;
		piecePlug.x = piecePlug.y = UNIT_SIZE / 2;
		piece.addChild(piecePlug);
		piece.filters = [GLOW_FILTER];
		
		pieceBite = new ScourgeLib_BiteMask();
		pieceBite.rotation = 180;
		pieceBite.visible = false;
		pieceBite.width = pieceBite.height = UNIT_SIZE * 0.7;
		pieceBite.blendMode = BlendMode.ERASE;
		piece.blendMode = BlendMode.LAYER;
		piece.addChild(pieceBite);
		
		pieceHandle = GUIFactory.makeContainer([piece]);
		pieceHandle.tabEnabled = !(pieceHandle.buttonMode = pieceHandle.useHandCursor = true);
		pieceHandle.x = wellBackground.width  / 2;
		pieceHandle.y = wellBackground.height / 2;
		piece.scaleX = piece.scaleY = wellBackground.height / (UNIT_SIZE * 5);
		
		GUIFactory.wireUp(pieceHandle, popPieceOnRollover, popPieceOnRollover);
		
		well.addChildAt(pieceHandle, 1);
		
		pieceHandle.addEventListener(MouseEvent.MOUSE_DOWN, liftPiece);
		grid.addEventListener(MouseEvent.MOUSE_DOWN, liftPiece);
		scene.addEventListener(MouseEvent.MOUSE_UP, dropPiece);
		
		toothContainer.addEventListener(MouseEvent.MOUSE_OVER, updateBiteTooth);
		toothContainer.addEventListener(MouseEvent.ROLL_OUT, updateBiteTooth);
		toothContainer.addEventListener(MouseEvent.MOUSE_DOWN, startBite);
		scene.addEventListener(MouseEvent.MOUSE_UP, endBite);
		
		stage.addEventListener(Event.ADDED, resize, true);
		stage.addEventListener(Event.RESIZE, resize);
		stage.addEventListener(KeyboardEvent.KEY_DOWN, keyHandler);
		stage.addEventListener(KeyboardEvent.KEY_UP, keyHandler);
		stage.addEventListener(MouseEvent.MOUSE_MOVE, mouseHandler);
		
		handlePushTimer = new Timer(10);
		handlePushTimer.addEventListener(TimerEvent.TIMER, updateHandlePush);
		
		
		game.begin(4);
		currentPlayer = game.getCurrentPlayer();
		currentPlayerIndex = game.getCurrentPlayerIndex();
		update(true, true);
		initHeads();
		//fillBoardRandomly();
	}
	
	private function resize(?event:Event):Void {
		
		if (event.type == Event.ADDED && event.target != flash.Lib.current) return;
		
		var sw:Float = stage.stageWidth;
		var sh:Float = stage.stageHeight;
		
		sw = Math.max(sw, MIN_WIDTH);
		sh = Math.max(sh, MIN_HEIGHT);
		
		background.scaleX = background.scaleY = 1;
		if (background.width / background.height < sw / sh) {
			background.width = sw;
			background.scaleY = background.scaleX;
		} else {
			background.height = sh;
			background.scaleX = background.scaleY;
		}
		
		bar.removeChild(well);
		
		bar.height = sh;
		bar.scaleX = bar.scaleY;
		bar.x = sw - bar.scaleX * BAR_WIDTH;
		bar.y = 0;
		
		// scale and reposition grid
		
		if (bar.x > sh) {
			grid.width = sh - 20;
			grid.scaleY = grid.scaleX;
		} else {
			grid.height = bar.x - 20;
			grid.scaleX = grid.scaleY;
		}
		grid.x = (bar.x - grid.width ) * 0.5;
		grid.y = (sh -    grid.height) * 0.5;
		
		bar.addChild(well);
	}
	
	private function update(?thePiece:Bool, ?thePlay:Bool):Void {
		if (thePlay) {
			updateGrid();
			updateHeads();
			updateGUIColors();
		}
		
		if (thePiece) {
			updatePiece();
			showPiece();
			updateWell();
		}
	}
	
	private function updateGUIColors():Void {
		var tween:Dynamic = {};
		tween.redMultiplier = teamCTs[currentPlayerIndex].redMultiplier;
		tween.greenMultiplier = teamCTs[currentPlayerIndex].greenMultiplier;
		tween.blueMultiplier = teamCTs[currentPlayerIndex].blueMultiplier;
		if (guiColorJob != null) guiColorJob.complete();
		guiColorJob = KTween.to(guiColorTransform, QUICK * 3, tween, POUNCE);
		guiColorJob.onChange = tweenGUIColors;
	}
	
	private function tweenGUIColors():Void {
		barBackground.transform.colorTransform = guiColorTransform;
		wellBackground.transform.colorTransform = guiColorTransform;
		somethingElse.transform.colorTransform = guiColorTransform;
		rotateRightButton.upState.transform.colorTransform = guiColorTransform;
		rotateLeftButton.upState.transform.colorTransform = guiColorTransform;
		swapButton.upState.transform.colorTransform = guiColorTransform;
		biteButton.upState.transform.colorTransform = guiColorTransform;
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
		
		var pt:Point;
		
		if (pieceCenter != null) {
			
			c1X = UNIT_SIZE * pieceCenter[0];
			c1Y = UNIT_SIZE * pieceCenter[1];
			
			pt = piece.globalToLocal(pieceHandle.localToGlobal(ORIGIN));
			
			offX = pt.x - c1X;
			offY = pt.y - c1Y;
			
			if (previousAngle > 0) {
				offX *= -1;
			} else if (previousAngle < 0) {
				offY *= -1;
			}
		}
		
		pieceRecipe = game.getPiece();
		pieceCenter = game.getPieceCenter();
		pieceHandle.rotation = 0;
		var lastAlpha:Float = pieceHandle.alpha;
		pieceHandle.transform.colorTransform = teamCTs[currentPlayerIndex];
		pieceHandle.alpha = lastAlpha;
		
		var c2X:Float = UNIT_SIZE * pieceCenter[0];
		var c2Y:Float = UNIT_SIZE * pieceCenter[1];
		
		// redraw the piece
		var ike:Int = 0, jen:Int = 0;
		while (jen < pieceBlocks.length) {
			var pieceBlock:Shape = pieceBlocks[jen];
			pieceBlock.x = UNIT_SIZE * pieceRecipe[ike];
			pieceBlock.y = UNIT_SIZE * pieceRecipe[ike + 1];
			if (ike + 2 < pieceRecipe.length) ike += 2;
			jen++;
		}
		
		pieceBite.x = pieceRecipe[ike    ] * UNIT_SIZE + pieceBlocks[jen - 1].width;
		pieceBite.y = pieceRecipe[ike + 1] * UNIT_SIZE + pieceBlocks[jen - 1].height;
		
		piecePlug.visible = (pieceRecipe == Pieces.O_PIECE);
		
		// update the position
		pieceHomeX = -c2X * piece.scaleX;
		pieceHomeY = -c2Y * piece.scaleY;
		
		if (draggingPiece) {
			piece.x = 0;
			piece.y = 0;
			pt = piece.globalToLocal(pieceHandle.localToGlobal(ORIGIN));
			piece.x = (pt.x - c2X + offY) * piece.scaleX;
			piece.y = (pt.y - c2Y + offX) * piece.scaleY;
			dragPiece(__snap);
		} else {
			piece.x = pieceHomeX;
			piece.y = pieceHomeY;
		}
		enableDrag();
	}
	
	private function updateGrid():Void {
		var gameGrid:Vector<UInt> = game.getGrid();
		var len:Int = Common.BOARD_NUM_CELLS;
		var rect:Rectangle = new Rectangle(0, 0, UNIT_SIZE, UNIT_SIZE);
		rect.inflate(1, 1);
		var rx:Int, ry:Int;
		
		prepareTeamBitmaps();
		
		for (ike in 0...len) {
			if (gameGrid[ike] > 0) {
				rx = ike % Common.BOARD_SIZE;
				ry = Std.int((ike - rx) / Common.BOARD_SIZE);
				rect.x = rx * UNIT_SIZE + BOARD_BORDER;
				rect.y = ry * UNIT_SIZE + BOARD_BORDER;
				rect.x -= 1;
				rect.y -= 1;
				teamBitmaps[gameGrid[ike] - 1].fillRect(rect, 0xFFFFFFFF);
			}
		}
		
		finishTeamBitmaps();
		
		gridTeams.addChild(teamBodies[currentPlayerIndex]);
	}
	
	private function initHeads():Void {
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
			
			bmp.applyFilter(bmp, bmp.rect, ORIGIN, SLIME_FILTER);
			bmp2.fillRect(bmp.rect, 0x0);
			bmp2.draw(bmp);
			
			bmp.fillRect(bmp.rect, 0xFFFFFFFF);
			bmp.copyChannel(bmp2, bmp.rect, ORIGIN, BitmapDataChannel.RED, BitmapDataChannel.ALPHA);
			bmp.applyFilter(bmp, bmp.rect, ORIGIN, BLUR_FILTER);
		}
		
		bmp2.fillRect(bmp2.rect, 0xFF000000);
		var mat:Matrix = new Matrix();
		mat.tx = -gridPattern.x;
		mat.ty = -gridPattern.y;
		for (ike in 0...Common.MAX_PLAYERS) bmp2.draw(teamBitmaps[ike], mat, null, BlendMode.ADD);
		gridBlurredPatternData.draw(gridPattern);
		gridBlurredPatternData.applyFilter(gridBlurredPatternData, gridBlurredPatternData.rect, ORIGIN, GRID_BLUR);
		//gridBlurredPatternData.fillRect(gridBlurredPatternData.rect, 0xFFFFFFFF);
		gridBlurredPatternData.copyChannel(bmp2, bmp2.rect, ORIGIN, BitmapDataChannel.RED, BitmapDataChannel.ALPHA);
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
	
	private function liftPiece(event:Event):Void {
		if (draggingPiece || biting) return;
		draggingPiece = true;
		pieceHandle.mouseEnabled = pieceHandle.mouseChildren = false;
		
		if (pieceHandleJob != null) pieceHandleJob.complete();
		if (pieceJob != null) pieceJob.complete();
		if (pieceHandleSpinJob != null) pieceHandleSpinJob.complete();
		
		pieceBoardScale = gridPattern.transform.concatenatedMatrix.a / piece.transform.concatenatedMatrix.a;
		
		popPiece(true);
		
		var mX:Float, mY:Float;
		if (event.currentTarget == grid) {
			mX = pieceCenter[0];
			mY = pieceCenter[1];
		} else {
			mX = piece.mouseX / UNIT_SIZE;
			mY = piece.mouseY / UNIT_SIZE;
		}
		
		var goodX:Float = mX, testX:Float;
		var goodY:Float = mY, testY:Float;
		var goodDist:Float = Math.POSITIVE_INFINITY, testDist:Float;
		
		var ike:Int = 0;
		while (ike < pieceRecipe.length) {
			testX = (pieceRecipe[ike] + 0.5) - mX;
			testY = (pieceRecipe[ike + 1] + 0.5) - mY;
			testDist = Math.sqrt(testX * testX + testY * testY);
			if (testDist < goodDist) {
				goodDist = testDist;
				goodX = testX + mX;
				goodY = testY + mY;
			}
			ike += 2;
		}
		
		var goodPt:Point = well.globalToLocal(piece.localToGlobal(new Point(goodX * UNIT_SIZE, goodY * UNIT_SIZE)));
		
		piece.x += pieceHandle.x;
		piece.y += pieceHandle.y;
		
		if (event.currentTarget == grid) {
			piece.x -= goodPt.x;
			piece.y -= goodPt.y;
			pieceHandle.scaleX = pieceHandle.scaleY = pieceBoardScale;
		} else {
			var toX:Float = piece.x  - goodPt.x;
			var toY:Float = piece.y  - goodPt.y;
			piece.x -= well.mouseX;
			piece.y -= well.mouseY;
			pieceJob = KTween.to(piece, 3 * QUICK, {x:toX, y:toY}, POUNCE);
			pieceHandleJob = KTween.to(pieceHandle, QUICK, {scaleX:1.2, scaleY:1.2}, Linear.easeOut);
		}
		
		dragPiece();
	}
	
	private function dragPiece(?snap:Bool):Void {
		if (!draggingPiece) return;
		var oldX:Float = pieceHandle.x;
		var oldY:Float = pieceHandle.y;
		
		var overGrid:Bool = gridBox.contains(gridPattern.mouseX, gridPattern.mouseY);
		var scale:Float;
		
		if (overGrid != pieceScaledDown) {
			pieceScaledDown = overGrid;
			if (pieceHandleJob != null) pieceHandleJob.complete();
			scale = overGrid ? pieceBoardScale : 1.2;
			pieceHandleJob = KTween.to(pieceHandle, 2 * QUICK, {scaleX:scale, scaleY:scale}, Linear.easeOut);
		}
		
		pieceHandle.x = well.mouseX;
		pieceHandle.y = well.mouseY;
		well.addChild(pieceHandle);
		
		if (overGrid && gridBox.containsRect(pieceHandle.getBounds(gridPattern))) {
			
			// grid snapping.
			
			var gp:Point = gridPattern.globalToLocal(piece.localToGlobal(ORIGIN));
			
			placeX = Std.int(Math.round(gp.x / UNIT_SIZE));
			placeY = Std.int(Math.round(gp.y / UNIT_SIZE));
			
			pieceHandle.transform.colorTransform = game.evaluatePosition(placeX, placeY) ? PLAIN_CT : teamCTs[currentPlayerIndex];
			
			var gp2:Point = new Point(placeX * UNIT_SIZE, placeY * UNIT_SIZE);
			
			gp  = pieceHandle.globalToLocal(gridPattern.localToGlobal(gp));
			gp2 = pieceHandle.globalToLocal(gridPattern.localToGlobal(gp2));
			
			gp2.x = pieceHandle.x + (gp2.x - gp.x) * pieceHandle.scaleX;
			gp2.y = pieceHandle.y + (gp2.y - gp.y) * pieceHandle.scaleY;
			
			if (!snap || Math.abs(pieceHandle.x + pieceHandle.y - handleGoalX - handleGoalY) < 2) {
				if (handlePushTimer.running) {
					pieceHandle.x = oldX;
					pieceHandle.y = oldY;
				} else {
					pieceHandle.x = gp2.x;
					pieceHandle.y = gp2.y;
				}
			} else if (snap) {
				handleGoalX = gp2.x;
				handleGoalY = gp2.y;
				pieceHandle.x = oldX;
				pieceHandle.y = oldY;
				handlePushTimer.start();
			}
		} else {
			placeX = placeY = -1;
			traceBox.text = "";
			handlePushTimer.reset();
		}
	}
	
	private function updateHandlePush(event:Event):Void {
		if (!draggingPiece) return;
		pieceHandle.x = pieceHandle.x * (1 - SNAP_RATE) + handleGoalX * SNAP_RATE;
		pieceHandle.y = pieceHandle.y * (1 - SNAP_RATE) + handleGoalY * SNAP_RATE;
		if (Math.abs(pieceHandle.x + pieceHandle.y - handleGoalX - handleGoalY) < 2) finishHandlePush();
	}
	
	private function finishHandlePush():Void {
		if (!(draggingPiece && handlePushTimer.running)) return;
		handlePushTimer.stop();
		pieceHandle.x = handleGoalX;
		pieceHandle.y = handleGoalY;
	}
	
	private function dropPiece(?event:Event):Void {
		if (!draggingPiece) return;
		pieceHandle.x = handleGoalX;
		pieceHandle.y = handleGoalY;
		handlePushTimer.stop();
		
		dragPiece();
		
		pieceHandle.transform.colorTransform = teamCTs[currentPlayerIndex];
		piece.filters = [GLOW_FILTER];
		pieceScaledDown = false;
		if (pieceHandleJob != null) pieceHandleJob.close();
		if (pieceJob != null) pieceJob.close();
		
		draggingPiece = false;
		
		if (placeX != -1 && game.processPlayerAction(PlayerAction.PLACE_PIECE(placeX, placeY))) {
			currentPlayer = game.getCurrentPlayer();
			currentPlayerIndex = game.getCurrentPlayerIndex();
			update(true, true);
		} else {
			pieceHandleJob = KTween.to(pieceHandle, 2 * QUICK, {x:wellBackground.width / 2, y:wellBackground.height / 2, scaleX:1, scaleY:1}, POUNCE, enableDrag);
			pieceJob = KTween.to(piece, 2 * QUICK, {x:pieceHomeX, y:pieceHomeY}, POUNCE);
			well.addChild(pieceHandle);
		}
	}
	
	private function showPiece():Void {
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
	}
	
	private function updateWell():Void {
		swapButton.alpha = (swapButton.mouseEnabled = currentPlayer.swaps > 0) ? 1 : 0.5;
		biteButton.alpha = (biteButton.mouseEnabled = currentPlayer.bites > 0) ? 1 : 0.5;
	}
	
	private function rotatePiece(?event:Event):Void {
		if (biting) return;
		finishHandlePush();
		if (pieceHandleSpinJob != null) pieceHandleSpinJob.complete();
		if (pieceJob != null) pieceJob.complete();
		var cc:Bool = event != null && event.currentTarget == rotateLeftButton;
		game.processPlayerAction(PlayerAction.SPIN_PIECE(cc));
		var angle:Int = cc ? -90 : 90;
		updatePiece(angle);
		pieceHandleSpinJob = KTween.from(pieceHandle, 2 * QUICK, {rotation:-angle}, POUNCE, enableDrag);
		if (!draggingPiece) pieceJob = KTween.to(piece, 2 * QUICK, {x:pieceHomeX, y:pieceHomeY}, POUNCE);
		pieceHandle.mouseEnabled = pieceHandle.mouseChildren = false;
	}
	
	private function rotateHint(event:Event):Void {
		if (draggingPiece || biting) return;
		if (pieceHandleSpinJob != null) pieceHandleSpinJob.complete();
		var angle:Float = (event.type == MouseEvent.ROLL_OUT) ? 0 : ((event.currentTarget == rotateLeftButton) ? -10 : 10);
		pieceHandleSpinJob = KTween.to(pieceHandle, QUICK, {rotation:angle}, POUNCE);
	}
	
	private function popPieceOnRollover(event:Event):Void {
		if (draggingPiece) return;
		popPiece(event.type == MouseEvent.ROLL_OVER);
	}
	
	private function popPiece(?bigger:Bool):Void {
		piece.filters = [bigger ? GLOW_FILTER_2 : GLOW_FILTER];
	}
	
	private function enableDrag():Void {
		pieceHandle.mouseEnabled = pieceHandle.mouseChildren = true;
		if (!draggingPiece) well.addChildAt(pieceHandle, 1);
	}
	
	private function keyHandler(event:KeyboardEvent):Void {
		var down:Bool = event.type == KeyboardEvent.KEY_DOWN;
		var wasDown:Bool = keyList[event.keyCode];
		if (down != wasDown) {
			switch (event.keyCode) {
				case Keyboard.SPACE: if (down) rotatePiece();
				case Keyboard.SHIFT: 
					if (!biting || shiftBite) {
						shiftBite = down;
						toggleBite(down);
					}
				case Keyboard.TAB: if (down) swapPiece();
				case Keyboard.ESCAPE: if (down) skipTurn();
			}
		}
		keyList[event.keyCode] = (event.type == KeyboardEvent.KEY_DOWN);
	}
	
	private function mouseHandler(event:MouseEvent):Void {
		if (draggingPiece) {
			dragPiece(__snap);
		} else if (draggingBite) {
			dragBite(__snap);
		}
	}
	
	private function biteHint(event:Event):Void {
		if (draggingPiece || biting) return;
		
		if (pieceHandleJob != null) pieceHandleJob.complete();
		if (pieceBiteJob != null) pieceBiteJob.complete();
		var over:Bool = event.type == MouseEvent.ROLL_OVER;
		if (over) {
			pieceBite.visible = true;
			pieceBite.alpha = 1;
			var wham:Float = wellBackground.width * 0.05;
			//pieceHandle.rotation = 30;
			pieceHandleJob = KTween.from(pieceHandle, 3 * QUICK, {x:pieceHandle.x + wham, y:pieceHandle.y + wham, rotation:0}, ZIGZAG);
		} else {
			pieceBite.alpha = 0.05;
			pieceBiteJob = KTween.to(pieceBite, 3 * QUICK, {alpha:0, visible:false}, POUNCE);
			//pieceHandleJob = KTween.to(pieceHandle, 3 * QUICK, {rotation:0}, POUNCE);
		}
	}
	
	private function toggleBite(?event:Event, ?isBiting:Null<Bool>):Void {
		if (!biteButton.mouseEnabled) return;
		cancelDragBite();
		if (isBiting == null) {
			biting = !biting;
		} else {
			biting = isBiting;
		}
		if (toothContainerJob != null) toothContainerJob.close();
		if (biting) {
			toothContainer.visible = true;
			toothContainer.mouseEnabled = toothContainer.mouseChildren = true;
			toothContainerJob = KTween.to(toothContainer, QUICK * 2, {alpha:1}, POUNCE);
			BITE_GLOW.color = TEAM_COLORS[currentPlayerIndex];
			toothContainer.filters = [BITE_GLOW];
			
			// We can optimize this to only happen when the baord is updated
			
			var br:Array<Bool> = game.getBiteGrid();
			var bx:Int, by:Int;
			for (ike in 0...br.length) {
				if (!br[ike]) continue;
				bx = ike % Common.BOARD_SIZE;
				by = Std.int((ike - bx) / Common.BOARD_SIZE);
				
				var tooth:Sprite;
				if (toothContainer.numChildren > ike) {
					tooth = cast(toothContainer.getChildAt(ike), Sprite);
					tooth.visible = true;
				} else {
					tooth = GUIFactory.makeTooth(UNIT_SIZE * 1.25);
				}
				tooth.transform.colorTransform = teamCTs[currentPlayerIndex];
				tooth.x = (bx + 0.5) * UNIT_SIZE;
				tooth.y = (by + 0.5) * UNIT_SIZE;
				toothContainer.addChild(tooth);
			}
		} else {
			toothContainer.mouseEnabled = toothContainer.mouseChildren = false;
			toothContainerJob = KTween.to(toothContainer, QUICK * 2, {alpha:0, visible:false}, POUNCE, hideTeeth);
		}
	}
	
	private function hideTeeth():Void {
		for (ike in 0...toothContainer.numChildren) toothContainer.getChildAt(ike).visible = false;
	}
	
	private function updateBiteTooth(event:Event):Void {
		if (draggingBite) return;
		if (event.type == MouseEvent.MOUSE_OVER) {
			// find the tooth beneath the mouse
			var teeth:Array<Dynamic> = grid.getObjectsUnderPoint(new Point(stage.mouseX, stage.mouseY));
			if (biteToothJob != null) biteToothJob.complete();
			var bX:Int = Std.int(toothContainer.mouseX / UNIT_SIZE);
			var bY:Int = Std.int(toothContainer.mouseY / UNIT_SIZE);
			for (ike in 0...teeth.length) {
				if (teeth[ike].name.indexOf("tooth") != 0) continue;
				var tooth:Sprite = cast(teeth[ike], Sprite);
				if (Std.int(tooth.x / UNIT_SIZE - 0.5) == bX && Std.int(tooth.y / UNIT_SIZE - 0.5) == bY) {
					biteTooth.visible = true;
					biteToothJob = KTween.to(biteTooth, QUICK, {scaleX:1, scaleY:1, alpha:1}, POUNCE);
					biteTooth.x = tooth.x + BOARD_BORDER;
					biteTooth.y = tooth.y + BOARD_BORDER;
					break;
				}
			}
		} else {
			biteToothJob = KTween.to(biteTooth, QUICK, {scaleX:0.5, scaleY:0.5, alpha:0, visible:false}, POUNCE, resetBiteTooth);
		}
	}
	
	private function startBite(?event:Event):Void {
		if (draggingBite) return;
		draggingBite = true;
		var bX:Int = Std.int(toothContainer.mouseX / UNIT_SIZE);
		var bY:Int = Std.int(toothContainer.mouseY / UNIT_SIZE);
		if (!game.processPlayerAction(PlayerAction.START_BITE(bX, bY))) return;
		biteLimits = game.getBiteLimits();
	}
	
	private function dragBite(?snap:Bool):Void {
		
		var dX:Int = Std.int(biteTooth.mouseX / UNIT_SIZE);
		var dY:Int = Std.int(biteTooth.mouseY / UNIT_SIZE);
		var horiz:Bool = false;
		
		if (bt2.x != bt1.x) {
			horiz = true;
		} else if (bt2.y != bt1.y) {
			horiz = false;
		} else if (dX == 0) {
			horiz = false;
		} else if (dY == 0) {
			horiz = true;
		} else {
			horiz = Math.abs(dX) > Math.abs(dY);
		}
		
		if (horiz) {
			bt2.x = Math.max(biteLimits[3], Math.min(biteLimits[1], dX)) * UNIT_SIZE;
		} else {
			bt2.y = Math.max(biteLimits[0], Math.min(biteLimits[2], dY)) * UNIT_SIZE;
		}
		
		bBody.graphics.clear();
		bBody.graphics.lineStyle(bt1.width, 0xFFFFFF, 1, null, LineScaleMode.NORMAL, CapsStyle.NONE);
		bBody.graphics.lineTo(bt2.x, bt2.y);
	}
	
	private function endBite(?event:Event):Void {
		if (!draggingBite) return;
		draggingBite = false;
		if (biteToothJob != null) biteToothJob.complete();
		var pt:Point = gridPattern.globalToLocal(bt2.localToGlobal(new Point()));
		var bX:Int = Std.int(pt.x / UNIT_SIZE);
		var bY:Int = Std.int(pt.y / UNIT_SIZE);
		if (bt2.x != bt1.x || bt2.y != bt1.y) {
			biteToothJob = KTween.to(biteTooth, QUICK, {scaleX:0.5, scaleY:0.5, alpha:0, visible:false}, POUNCE, resetBiteTooth);
		}
		if (game.processPlayerAction(PlayerAction.END_BITE(bX, bY))) {
			toggleBite(null, false);
			update(false, true);
		}
	}
	
	private function resetBiteTooth():Void {
		bt2.x = bt2.y = 0;
		bBody.graphics.clear();
	}
	
	private function cancelDragBite():Void {
		if (!draggingBite) return;
		draggingBite = false;
	}
	
	private function swapHint(event:Event):Void {
		if (draggingPiece || biting) return;
		if (event.type == MouseEvent.ROLL_OVER) {
			swapHinting = true;
			piecePlug.visible = false;
			currentBlockForSwapHint = 0;
			pushCurrentSwapBlock();
			pieceHandle.filters = [SWAP_FILTER];
		} else {
			swapHinting = false;
			var oldPieceX:Float = piece.x;
			var oldPieceY:Float = piece.y;
			var oldXs:Array<Float> = [];
			var oldYs:Array<Float> = [];
			for (ike in 0...pieceBlocks.length) {
				oldXs[ike] = pieceBlocks[ike].x;
				oldYs[ike] = pieceBlocks[ike].y;
				if (pieceBlockJobs[ike] != null) pieceBlockJobs[ike].abort();
			}
			updatePiece();
			KTween.from(piece, QUICK, {x:oldPieceX, y:oldPieceY}, POUNCE);
			for (ike in 0...pieceBlocks.length) {
				pieceBlockJobs[ike] = KTween.from(pieceBlocks[ike], QUICK, {x:oldXs[ike], y:oldYs[ike]}, POUNCE);
			}
			pieceHandle.filters = [];
			piece.filters = [GLOW_FILTER];
		}
	}
	
	private function pushCurrentSwapBlock():Void {
		if (!swapHinting) return;
		var block:Shape = pieceBlocks[currentBlockForSwapHint];
		var spotTaken:Bool;
		var spotX:Float = 0, spotY:Float = 0;
		while (true) {
			spotTaken = false;
			spotX = (Math.floor(Math.random() * 3) - 1.5 + pieceCenter[0]) * UNIT_SIZE;
			spotY = (Math.floor(Math.random() * 3) - 1.5 + pieceCenter[1]) * UNIT_SIZE;
			
			for (ike in 0...pieceBlocks.length) {
				if (pieceBlockJobs[ike] != null) pieceBlockJobs[ike].abort();
				spotTaken = spotTaken || (pieceBlocks[ike].x == spotX && pieceBlocks[ike].y == spotY);
			}
			
			if (!spotTaken) break;
		}
		
		if (pieceBlockJobs[currentBlockForSwapHint] != null) pieceBlockJobs[currentBlockForSwapHint].close();
		pieceBlockJobs[currentBlockForSwapHint] = KTween.to(block, QUICK * 0.7, {x:spotX, y:spotY}, Linear.easeOut, pushCurrentSwapBlock);
		
		currentBlockForSwapHint = (currentBlockForSwapHint + 1) % pieceBlocks.length;
	}
	
	private function swapPiece(?event:Event):Void {
		if (draggingPiece || biting || !swapButton.mouseEnabled) return;
		swapHinting = false;
		game.processPlayerAction(PlayerAction.SWAP_PIECE);
		for (ike in 0...pieceBlocks.length) {
			if (pieceBlockJobs[ike] != null) pieceBlockJobs[ike].abort();
		}
		update(true);
		if (pieceRecipe == Pieces.O_PIECE) KTween.from(piecePlug, QUICK, {alpha:0}, POUNCE);
	}
	
	private function skipTurn(?event:Event):Void {
		if (draggingPiece || draggingBite) return;
		game.processPlayerAction(PlayerAction.SKIP);
		currentPlayer = game.getCurrentPlayer();
		currentPlayerIndex = game.getCurrentPlayerIndex();
		update(true, true);
	}
}