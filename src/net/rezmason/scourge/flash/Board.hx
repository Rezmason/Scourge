package net.rezmason.scourge.flash;

import flash.display.BitmapData;
import flash.display.BitmapDataChannel;
import flash.display.BlendMode;
import flash.display.MovieClip;
import flash.display.Shape;
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
import flash.text.TextField;
import flash.ui.Keyboard;
import flash.utils.Timer;

import net.kawa.tween.KTween;
import net.kawa.tween.KTJob;
import net.kawa.tween.easing.Elastic;
import net.kawa.tween.easing.Linear;
import net.kawa.tween.easing.Quad;

import net.rezmason.scourge.Common;
import net.rezmason.scourge.Layout;
import net.rezmason.scourge.Game;
import net.rezmason.scourge.Player;
import net.rezmason.scourge.PlayerAction;
import net.rezmason.scourge.Pieces;

import flash.Lib;

class Board {
	
	inline static var __snap:Bool = true; // not sure if I want this
	
	inline static var MIN_WIDTH:Int = 400;
	inline static var MIN_HEIGHT:Int = 300;
	inline static var SNAP_RATE:Float = 0.3;
	
	private static var SLIME_MAKER:GlowFilter = new GlowFilter(0x0, 1, 14, 14, 2.5, 1, true);
	private static var BLUR_FILTER:BlurFilter = new BlurFilter(6, 6, 2);
	private static var PIECE_GLOW:GlowFilter = new GlowFilter(0xFFFFFF, 1, 7, 7, 20, 1, true);
	private static var PIECE_POP_GLOW:GlowFilter = new GlowFilter(0xFFFFFF, 1, 10, 10, 20, 1, true);
	private static var PIECE_SWAP_GLOW:GlowFilter = new GlowFilter(0xFFFFFF, 1, 10, 10, 8, 1);
	private static var GRID_BLUR:BlurFilter = new BlurFilter(4, 4, 1);
	
	private static var PLAIN_CT:ColorTransform = GUIFactory.makeCT(0xFFFFFF);
	private static var TEAM_COLORS:Array<Int> = [0xFF0090, 0xFFC800, 0x30FF00, 0x00C0FF];
	private static var ORIGIN:Point = new Point();
	
	public static var QUICK:Float = 0.1;
	public static var POUNCE:Float -> Float = Quad.easeOut;
	public static var ZIGZAG:Float -> Float = Elastic.easeOut;
	
	private var game:Game;
	private var scene:Sprite;
	private var stage:Stage;
	private var teamCTs:Array<ColorTransform>;
	private var currentPlayer:Player;
	private var currentPlayerIndex:Int;
	private var shiftBite:Bool;
	private var background:Shape;
	private var grid:GameGrid;
	private var bar:Sprite;
	private var biteTooth:BiteTooth;
	private var barBackground:Shape;
	private var well:Well;
	private var statPanel:StatPanel;
	private var timerPanel:TimerPanel;
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
	private var gridHitBox:Rectangle;
	private var pieceBoardScale:Float;
	private var pieceScaledDown:Bool;
	private var pieceLocX:Int;
	private var pieceLocY:Int;
	private var handleGoalX:Float;
	private var handleGoalY:Float;
	private var handlePushTimer:Timer;
	private var keyList:Array<Bool>;
	private var biteLimits:Array<Int>;
	private var biteIndicator:MovieClip;
	private var teeth:Array<Sprite>;
	
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
	private var gridTeethJob:KTJob;
	private var biteToothJob:KTJob;
	private var faderJob:KTJob;
	private var swapCounterJob:KTJob;
	private var biteCounterJob:KTJob;
	
	private var overBiteButton:Bool;
	private var overSwapButton:Bool;
	private var currentBlockForSwapHint:Int;
	
	private var pieceHomeX:Float;
	private var pieceHomeY:Float;
	
	public function new(__game:Game, __scene:Sprite) {
		scene = __scene;
		game = __game;
		
		scene.mouseEnabled = scene.mouseChildren = false;
		
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
		
		// initialize the primitive variables
		draggingPiece = false;
		pieceScaledDown = false;
		draggingBite = false;
		swapHinting = false;
		biting = false;
		pieceBlockJobs = [];
		teeth = [];
		keyList = [];
		guiColorTransform = new ColorTransform();
		overSwapButton = false;
		overBiteButton = false;
		
		// create the team color transforms
		teamCTs = [];
		for (ike in 0...TEAM_COLORS.length) teamCTs[ike] = GUIFactory.makeCT(TEAM_COLORS[ike]);
		
		// populate teamHeads and teamBodies
		teamHeads = [];
		teamBodies = [];
		teamBitmaps = [];
		var bmp:BitmapData;
		var shp:Shape;
		var bmpSize:Int = Common.BOARD_SIZE * Layout.UNIT_SIZE + 2 * Layout.BOARD_BORDER;
		for (ike in 0...Common.MAX_PLAYERS) {
			bmp = new BitmapData(bmpSize, bmpSize, true, 0x0);
			teamBitmaps.push(bmp);
			
			teamBodies.push(GUIFactory.makeBitmapShape(bmp, 1, true, teamCTs[ike]));
			teamHeads.push(GUIFactory.makeHead(Layout.UNIT_SIZE, teamCTs[ike]));
		}
		
		// build the scene
		background = GUIFactory.drawSolidRect(new Shape(), 0x0, 1, 0, 0, 800, 600);
		grid = new GameGrid();
		biteTooth = grid.biteTooth;
		GUIFactory.fillSprite(grid.heads, teamHeads.copy());
		GUIFactory.fillSprite(grid.teams, teamBodies.copy());
		traceBox = GUIFactory.makeTextBox(400, 100, "_sans", 24);
		well = new Well();
		timerPanel = new TimerPanel();
		statPanel = new StatPanel(Layout.STAT_PANEL_HEIGHT);
		barBackground = GUIFactory.drawSolidRect(new Shape(), 0x444444, 1, 150, 0, Layout.BAR_WIDTH - 150, Layout.BAR_HEIGHT);
		bar = GUIFactory.makeContainer([barBackground, timerPanel, statPanel, well]);
		
		// wire up the scene
		GUIFactory.wireUp(well.rotateRightButton, rotateHint, rotateHint, rotatePiece);
		GUIFactory.wireUp(well.rotateLeftButton, rotateHint, rotateHint, rotatePiece);
		GUIFactory.wireUp(well.biteButton, biteHint, biteHint, toggleBite);
		GUIFactory.wireUp(well.swapButton, swapHint, swapHint, swapPiece);
		GUIFactory.wireUp(timerPanel.skipButton, null, null, skipTurn);
		
		gridHitBox = grid.getHitBox();
		gridHitBox.inflate(Layout.UNIT_SIZE * 1.5, Layout.UNIT_SIZE * 1.5);
		
		// position things
		well.x = well.y = Layout.BAR_MARGIN;
		timerPanel.x = Layout.BAR_MARGIN;
		timerPanel.y = well.y + well.height + Layout.BAR_MARGIN;
		statPanel.x = Layout.BAR_MARGIN;
		statPanel.y = timerPanel.y + timerPanel.height + Layout.BAR_MARGIN;
		
		GUIFactory.fillSprite(scene, [background, grid, bar, traceBox]);
		
		// Set up the piece, piece handle, piece blocks and piece bite
		pieceBlocks = [];
		var bW:Int = Layout.UNIT_SIZE + 2;
		for (ike in 0...Common.MOST_BLOCKS_IN_PIECE + 1) {
			pieceBlocks.push(GUIFactory.drawSolidRect(new Shape(), 0x222222, 1, -1, -1, bW, bW, bW * 0.5));
		}
		piece = GUIFactory.makeContainer(pieceBlocks.copy());
		piecePlug = GUIFactory.drawSolidRect(new Shape(), 0x222222, 1, 0, 0, bW, bW, bW);
		piecePlug.visible = false;
		piecePlug.x = piecePlug.y = Layout.UNIT_SIZE / 2;
		piece.addChild(piecePlug);
		piece.filters = [PIECE_GLOW];
		pieceBite = new ScourgeLib_BiteMask();
		pieceBite.rotation = 180;
		pieceBite.visible = false;
		pieceBite.width = pieceBite.height = Layout.UNIT_SIZE * 0.7;
		pieceBite.blendMode = BlendMode.ERASE;
		piece.blendMode = BlendMode.LAYER;
		piece.addChild(pieceBite);
		pieceHandle = GUIFactory.makeContainer([piece]);
		pieceHandle.tabEnabled = !(pieceHandle.buttonMode = pieceHandle.useHandCursor = true);
		pieceHandle.x = Layout.WELL_WIDTH  / 2;
		pieceHandle.y = Layout.WELL_WIDTH / 2;
		piece.scaleX = piece.scaleY = Layout.WELL_WIDTH / (Layout.UNIT_SIZE * 5);
		
		// wire up the piece handle
		GUIFactory.wireUp(pieceHandle, popPieceOnRollover, popPieceOnRollover);
		
		well.addChildAt(pieceHandle, 1);
		
		// add events
		pieceHandle.addEventListener(MouseEvent.MOUSE_DOWN, liftPiece);
		grid.addEventListener(MouseEvent.MOUSE_DOWN, liftPiece);
		stage.addEventListener(MouseEvent.MOUSE_UP, dropPiece);
		
		grid.teeth.addEventListener(MouseEvent.MOUSE_OVER, updateBiteTooth);
		grid.teeth.addEventListener(MouseEvent.ROLL_OUT, updateBiteTooth);
		grid.teeth.addEventListener(MouseEvent.MOUSE_DOWN, firstBite);
		stage.addEventListener(MouseEvent.MOUSE_UP, endBite);
		
		stage.addEventListener(Event.ADDED, resize, true);
		stage.addEventListener(Event.RESIZE, resize);
		stage.addEventListener(KeyboardEvent.KEY_DOWN, keyHandler);
		stage.addEventListener(KeyboardEvent.KEY_UP, keyHandler);
		stage.addEventListener(MouseEvent.MOUSE_MOVE, mouseHandler);
		
		handlePushTimer = new Timer(10);
		handlePushTimer.addEventListener(TimerEvent.TIMER, updateHandlePush);
		
		// kick things off
		game.begin(4);
		currentPlayer = game.getCurrentPlayer();
		currentPlayerIndex = game.getCurrentPlayerIndex();
		update(true, true);
		initHeads();
		//fillBoardRandomly();
		scene.mouseEnabled = scene.mouseChildren = true;
	}
	
	private function resize(?event:Event):Void {
		
		if (event.type == Event.ADDED && event.target != flash.Lib.current) return;
		
		var sw:Float = stage.stageWidth;
		var sh:Float = stage.stageHeight;
		
		sw = Math.max(sw, MIN_WIDTH);
		sh = Math.max(sh, MIN_HEIGHT);
		
		// size the background. This is more //important later when I texture it
		background.scaleX = background.scaleY = 1;
		if (background.width / background.height < sw / sh) {
			background.width = sw;
			background.scaleY = background.scaleX;
		} else {
			background.height = sh;
			background.scaleX = background.scaleY;
		}
		
		bar.height = sh;
		bar.scaleX = bar.scaleY;
		bar.x = sw - bar.scaleX * Layout.BAR_WIDTH;
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
	}
	
	private function update(?thePiece:Bool, ?thePlay:Bool, ?fade:Bool):Void {
		
		if (thePlay) {
			// fades the board from its old state to the new one.
			if (faderJob != null) faderJob.complete();
			if (fade) {
				var biteToothWasVisible:Bool = grid.biteTooth.visible;
				grid.teeth.visible = grid.biteTooth.visible = false;
				grid.faderBitmap.fillRect(grid.faderBitmap.rect, 0x0);
				var mat:Matrix = new Matrix(1, 0, 0, 1, -Layout.BOARD_BORDER, -Layout.BOARD_BORDER);
				grid.faderBitmap.draw(grid, mat);
				grid.teeth.visible = true;
				grid.biteTooth.visible = biteToothWasVisible;
				grid.fader.alpha = 0.75;
				grid.fader.visible = true;
				faderJob = KTween.to(grid.fader, QUICK * 5, {alpha:0, visible:false}, POUNCE);
			}
			
			updateGrid();
			updateHeads();
			cycleGUIColors();
		}
		
		if (thePiece) {
			if (!biting) {
				updatePiece();
				showPiece();
			}
			updateWell();
			updateStats();
		}
	}
	
	private function cycleGUIColors():Void {
		var tween:Dynamic = {};
		tween.redMultiplier = teamCTs[currentPlayerIndex].redMultiplier;
		tween.greenMultiplier = teamCTs[currentPlayerIndex].greenMultiplier;
		tween.blueMultiplier = teamCTs[currentPlayerIndex].blueMultiplier;
		if (guiColorJob != null) guiColorJob.complete();
		guiColorJob = KTween.to(guiColorTransform, QUICK * 3, tween, POUNCE);
		guiColorJob.onChange = tweenGUIColors;
	}
	
	private function tweenGUIColors():Void {
		well.tint(guiColorTransform);
		statPanel.tint(guiColorTransform);
		timerPanel.tint(guiColorTransform);
		//barBackground.transform.colorTransform = guiColorTransform;
	}
	
	private function updateHeads():Void {
		var numPlayers:Int = game.getNumPlayers();
		for (ike in 0...numPlayers) {
			var head:Shape = teamHeads[ike];
			if (head.alpha == 1 && !game.isPlayerAlive(ike)) {
				KTween.to(head, QUICK * 5, {scaleX:1, scaleY:1, alpha:0, visible:false}, Linear.easeOut);
			} else {
				head.visible = true;
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
			
			c1X = Layout.UNIT_SIZE * pieceCenter[0];
			c1Y = Layout.UNIT_SIZE * pieceCenter[1];
			
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
		
		var c2X:Float = Layout.UNIT_SIZE * pieceCenter[0];
		var c2Y:Float = Layout.UNIT_SIZE * pieceCenter[1];
		
		// redraw the piece
		var ike:Int = 0, jen:Int = 0;
		while (jen < pieceBlocks.length) {
			var pieceBlock:Shape = pieceBlocks[jen];
			pieceBlock.x = Layout.UNIT_SIZE * pieceRecipe[ike];
			pieceBlock.y = Layout.UNIT_SIZE * pieceRecipe[ike + 1];
			if (ike + 2 < pieceRecipe.length) ike += 2;
			jen++;
		}
		
		pieceBite.x = pieceRecipe[ike    ] * Layout.UNIT_SIZE + pieceBlocks[jen - 1].width;
		pieceBite.y = pieceRecipe[ike + 1] * Layout.UNIT_SIZE + pieceBlocks[jen - 1].height;
		
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
		var gameGrid:Array<Int> = game.getColorGrid();
		var len:Int = Common.BOARD_NUM_CELLS;
		var rect:Rectangle = new Rectangle(0, 0, Layout.UNIT_SIZE, Layout.UNIT_SIZE);
		rect.inflate(1, 1);
		var rx:Int, ry:Int;
		
		prepareTeamBitmaps();
		
		for (ike in 0...len) {
			if (gameGrid[ike] > 0) {
				rx = ike % Common.BOARD_SIZE;
				ry = Std.int((ike - rx) / Common.BOARD_SIZE);
				rect.x = rx * Layout.UNIT_SIZE + Layout.BOARD_BORDER;
				rect.y = ry * Layout.UNIT_SIZE + Layout.BOARD_BORDER;
				rect.x -= 1;
				rect.y -= 1;
				teamBitmaps[gameGrid[ike] - 1].fillRect(rect, 0xFFFFFFFF);
			}
		}
		
		finishTeamBitmaps();
		
		grid.teams.addChild(teamBodies[currentPlayerIndex]);
	}
	
	private function initHeads():Void {
		var heads:Array<Int> = Common.HEADS[game.getNumPlayers() - 1];
		
		for (ike in 0...Common.MAX_PLAYERS) {
			var head:Shape = teamHeads[ike];
			if (ike * 2 < heads.length) {
				head.visible = true;
				head.alpha = 1;
				head.x = (heads[ike * 2    ] + 0.5) * Layout.UNIT_SIZE;
				head.y = (heads[ike * 2 + 1] + 0.5) * Layout.UNIT_SIZE;
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
		var bmpSize:Int = Common.BOARD_SIZE * Layout.UNIT_SIZE + 2 * Layout.BOARD_BORDER;
		var bmp2:BitmapData = new BitmapData(bmpSize, bmpSize, true, 0x0);
		
		for (ike in 0...Common.MAX_PLAYERS) {
			bmp = teamBitmaps[ike];
			
			bmp.applyFilter(bmp, bmp.rect, ORIGIN, SLIME_MAKER);
			bmp2.fillRect(bmp.rect, 0x0);
			bmp2.draw(bmp);
			
			bmp.fillRect(bmp.rect, 0xFFFFFFFF);
			bmp.copyChannel(bmp2, bmp.rect, ORIGIN, BitmapDataChannel.RED, BitmapDataChannel.ALPHA);
			bmp.applyFilter(bmp, bmp.rect, ORIGIN, BLUR_FILTER);
		}
		
		bmp2.fillRect(bmp2.rect, 0xFF000000);
		var mat:Matrix = new Matrix();
		mat.tx = -grid.pattern.x;
		mat.ty = -grid.pattern.y;
		for (ike in 0...Common.MAX_PLAYERS) bmp2.draw(teamBitmaps[ike], mat, null, BlendMode.ADD);
		grid.blurredPatternData.draw(grid.pattern);
		grid.blurredPatternData.applyFilter(grid.blurredPatternData, grid.blurredPatternData.rect, ORIGIN, GRID_BLUR);
		//grid.blurredPatternData.fillRect(grid.blurredPatternData.rect, 0xFFFFFFFF);
		grid.blurredPatternData.copyChannel(bmp2, bmp2.rect, ORIGIN, BitmapDataChannel.RED, BitmapDataChannel.ALPHA);
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
					rx = Std.int(Math.random() * Common.BOARD_SIZE) * Layout.UNIT_SIZE;
					ry = Std.int(Math.random() * Common.BOARD_SIZE) * Layout.UNIT_SIZE;
					if (whatev[ry] == null) {
						whatev[ry] = [];
					}
					if (whatev[ry][rx] == null) {
						whatev[ry][rx] = true;
						break;
					}
				}	
				rect.x = rx + Layout.BOARD_BORDER;
				rect.y = ry + Layout.BOARD_BORDER;
				rect.width = rect.height = Layout.UNIT_SIZE;
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
		
		pieceBoardScale = grid.pattern.transform.concatenatedMatrix.a / piece.transform.concatenatedMatrix.a;
		
		popPiece(true);
		
		var mX:Float, mY:Float;
		if (event.currentTarget == grid) {
			mX = pieceCenter[0];
			mY = pieceCenter[1];
		} else {
			mX = piece.mouseX / Layout.UNIT_SIZE;
			mY = piece.mouseY / Layout.UNIT_SIZE;
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
		
		var goodPt:Point = well.globalToLocal(piece.localToGlobal(new Point(goodX * Layout.UNIT_SIZE, goodY * Layout.UNIT_SIZE)));
		
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
		
		var overGrid:Bool = gridHitBox.contains(grid.pattern.mouseX, grid.pattern.mouseY);
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
		
		if (overGrid && gridHitBox.containsRect(pieceHandle.getBounds(grid.pattern))) {
			
			// grid snapping.
			
			var gp:Point = grid.pattern.globalToLocal(piece.localToGlobal(ORIGIN));
			
			pieceLocX = Std.int(Math.round(gp.x / Layout.UNIT_SIZE));
			pieceLocY = Std.int(Math.round(gp.y / Layout.UNIT_SIZE));
			
			pieceHandle.transform.colorTransform = game.evaluatePosition(pieceLocX, pieceLocY) ? PLAIN_CT : teamCTs[currentPlayerIndex];
			
			var gp2:Point = new Point(pieceLocX * Layout.UNIT_SIZE, pieceLocY * Layout.UNIT_SIZE);
			
			gp  = pieceHandle.globalToLocal(grid.pattern.localToGlobal(gp));
			gp2 = pieceHandle.globalToLocal(grid.pattern.localToGlobal(gp2));
			
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
			pieceLocX = pieceLocY = -1;
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
		piece.filters = [PIECE_GLOW];
		pieceScaledDown = false;
		if (pieceHandleJob != null) pieceHandleJob.close();
		if (pieceJob != null) pieceJob.close();
		
		draggingPiece = false;
		
		if (pieceLocX != -1 && game.processPlayerAction(PlayerAction.PLACE_PIECE(pieceLocX, pieceLocY))) {
			currentPlayer = game.getCurrentPlayer();
			currentPlayerIndex = game.getCurrentPlayerIndex();
			update(true, true, true);
		} else {
			var pieceHandleHome:Float = Layout.WELL_WIDTH / 2;
			pieceHandleJob = KTween.to(pieceHandle, 2 * QUICK, {x:pieceHandleHome, y:pieceHandleHome, scaleX:1, scaleY:1}, POUNCE, enableDrag);
			pieceJob = KTween.to(piece, 2 * QUICK, {x:pieceHomeX, y:pieceHomeY}, POUNCE);
			well.addChild(pieceHandle);
		}
	}
	
	private function showPiece():Void {
		if (biteIndicator != null) {
			biteIndicator.gotoAndStop(0);
			biteIndicator.visible = false;
		}
		pieceHandle.visible = true;
		well.addChildAt(pieceHandle, 1);
		piece.x = pieceHomeX;
		piece.y = pieceHomeY;
		pieceHandle.x = Layout.WELL_WIDTH  / 2;
		pieceHandle.y = Layout.WELL_WIDTH / 2;
		pieceHandle.scaleX = pieceHandle.scaleY = 0.7;
		pieceHandle.alpha = 0;
		pieceHandle.mouseEnabled = pieceHandle.mouseChildren = false;
		if (pieceHandleJob != null) pieceHandleJob.close();
		if (pieceHandleSpinJob != null) pieceHandleSpinJob.complete();
		pieceHandleJob = KTween.to(pieceHandle, 3 * QUICK, {alpha:1, scaleX:1, scaleY:1}, POUNCE, enableDrag);
	}
	
	private function updateWell():Void {
		if (swapCounterJob != null) swapCounterJob.complete();
		if (biteCounterJob != null) biteCounterJob.complete();
		well.updateCounters(currentPlayer.swaps, currentPlayer.bites);
	}
	
	private function updateStats():Void {
		statPanel.update(game.getRollCall(), teamCTs);
	}
	
	private function rotatePiece(?event:Event):Void {
		if (biting) return;
		finishHandlePush();
		if (pieceHandleSpinJob != null) pieceHandleSpinJob.complete();
		if (pieceJob != null) pieceJob.complete();
		var cc:Bool = event != null && event.currentTarget == well.rotateLeftButton;
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
		var angle:Float = (event.type == MouseEvent.ROLL_OUT) ? 0 : ((event.currentTarget == well.rotateLeftButton) ? -10 : 10);
		pieceHandleSpinJob = KTween.to(pieceHandle, QUICK, {rotation:angle}, POUNCE);
	}
	
	private function popPieceOnRollover(event:Event):Void {
		if (draggingPiece) return;
		popPiece(event.type == MouseEvent.ROLL_OVER);
	}
	
	private function popPiece(?bigger:Bool):Void {
		piece.filters = [bigger ? PIECE_POP_GLOW : PIECE_GLOW];
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
						toggleBite(null, down);
					}
				case Keyboard.TAB: if (down) swapPiece();
				case Keyboard.ESCAPE: if (down) skipTurn();
				case Keyboard.F1: untyped __global__["flash.profiler.showRedrawRegions"](down);
				case Keyboard.F2:
					if (down) {
						var gridString:String = game.getColorGrid().toString() + ",";
						for (ike in 0...Common.BOARD_SIZE) {
							Lib.trace(gridString.substr(ike * Common.BOARD_SIZE * 2, Common.BOARD_SIZE * 2));
						}
					}
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
		
		if (biteCounterJob != null) biteCounterJob.complete();
		if (pieceHandleJob != null) pieceHandleJob.complete();
		if (pieceBiteJob != null) pieceBiteJob.complete();
		overBiteButton = event.type == MouseEvent.ROLL_OVER;
		if (overBiteButton) {
			pieceBite.visible = true;
			pieceBite.alpha = 1;
			var wham:Float = Layout.WELL_WIDTH * 0.05;
			//pieceHandle.rotation = 30;
			pieceHandleJob = KTween.from(pieceHandle, 3 * QUICK, {x:pieceHandle.x + wham, y:pieceHandle.y + wham, rotation:0}, ZIGZAG);
			well.biteCounter.visible = true;
			well.biteCounter.alpha = 0;
			biteCounterJob = KTween.to(well.biteCounter, 3 * QUICK, {alpha:1}, POUNCE);
		} else {
			pieceBite.alpha = 0.05;
			pieceBiteJob = KTween.to(pieceBite, 3 * QUICK, {alpha:0, visible:false}, POUNCE);
			//pieceHandleJob = KTween.to(pieceHandle, 3 * QUICK, {rotation:0}, POUNCE);
			well.biteCounter.alpha = 1;
			biteCounterJob = KTween.to(well.biteCounter, 3 * QUICK, {alpha:0, visible:false}, POUNCE);
		}
	}
	
	private function toggleBite(?event:Event, ?isBiting:Null<Bool>):Void {
		if (currentPlayer.bites < 1 && isBiting != false) return;
		cancelDragBite();
		var switched:Bool = false;
		if (isBiting == null) {
			biting = !biting;
			switched = true;
		} else {
			switched = biting != isBiting;
			biting = isBiting;
		}
		if (gridTeethJob != null) gridTeethJob.close();
		if (biteToothJob != null) biteToothJob.close();
		if (biting) {
			switch (game.getCurrentPlayer().biteSize) {
				case 1:biteIndicator = well.smallBiteIndicator;
				case 2:biteIndicator = well.bigBiteIndicator;
				case 3:biteIndicator = well.superBiteIndicator;
			}
			biteIndicator.visible = true;
			biteIndicator.transform.colorTransform = teamCTs[currentPlayerIndex];
			pieceHandle.visible = false;
			biteIndicator.gotoAndPlay("in");
			
			grid.teeth.visible = true;
			grid.teeth.mouseEnabled = grid.teeth.mouseChildren = true;
			gridTeethJob = KTween.to(grid.teeth, QUICK * 2, {alpha:1}, POUNCE);
			grid.tint(TEAM_COLORS[currentPlayerIndex]);
			
			
			if (!overBiteButton) {
				if (biteCounterJob != null) biteCounterJob.complete();
				well.biteCounter.visible = true;
				well.biteCounter.alpha = 0;
				biteCounterJob = KTween.to(well.biteCounter, 3 * QUICK, {alpha:1}, POUNCE);
			}
			
			updateTeeth();
			
		} else {
			if (biteIndicator != null && biteIndicator.visible) showPiece();
			grid.teeth.mouseEnabled = grid.teeth.mouseChildren = false;
			gridTeethJob = KTween.to(grid.teeth, QUICK * 2, {alpha:0, visible:false}, POUNCE, hideTeeth);
			biteToothJob = KTween.to(biteTooth, QUICK, {scaleX:0.5, scaleY:0.5, alpha:0, visible:false}, POUNCE, biteTooth.reset);
			teamHeads[currentPlayerIndex].visible = true;
			pieceBite.visible = false;
			
			if (!overBiteButton && switched) {
				if (biteCounterJob != null) biteCounterJob.complete();
				well.biteCounter.visible = true;
				well.biteCounter.alpha = 1;
				biteCounterJob = KTween.to(well.biteCounter, 3 * QUICK, {alpha:0, visible:false}, POUNCE);
			}
		}
	}
	
	private function hideTeeth():Void {
		//for (ike in 0...grid.teeth.numChildren) grid.teeth.getChildAt(ike).visible = false;
	}
	
	private function updateTeeth():Void {
		
		// We can optimize this to only happen when the baord is updated
		var head:Shape = teamHeads[currentPlayerIndex];
		var br:Array<Bool> = game.getBiteGrid();
		var bx:Int, by:Int;
		var totalTeeth:Int = grid.teeth.numChildren;
		var heads:Array<Int> = Common.HEADS[game.getNumPlayers() - 1];
		var headX:Int = heads[currentPlayerIndex * 2    ];
		var headY:Int = heads[currentPlayerIndex * 2 + 1];
		var tooth:Sprite;
		var toothItr:Int = 0;
		
		for (ike in 0...br.length) {
			if (!br[ike]) continue;
			by = Std.int(ike / Common.BOARD_SIZE);
			bx = ike - by * Common.BOARD_SIZE;
			if (bx == headX && by == headY) head.visible = false;
			
			if (toothItr > teeth.length - 1) {
				tooth = GUIFactory.makeTooth(Layout.UNIT_SIZE * 1.25);
				teeth.push(tooth);
			} else {
				tooth = teeth[toothItr];
				tooth.visible = true;
			}
			
			tooth.transform.colorTransform = teamCTs[currentPlayerIndex];
			tooth.x = (bx + 0.5) * Layout.UNIT_SIZE;
			tooth.y = (by + 0.5) * Layout.UNIT_SIZE;
			grid.teeth.addChild(tooth);
			
			toothItr++;
		}
		for (ike in toothItr...teeth.length) teeth[ike].visible = false;
	}
	
	private function updateBiteTooth(event:Event):Void {
		if (draggingBite) return;
		if (biteToothJob != null) biteToothJob.complete();
		if (event.type == MouseEvent.MOUSE_OVER) {
			var tooth:Sprite = cast(event.target, Sprite);
			biteTooth.visible = true;
			biteToothJob = KTween.to(biteTooth, QUICK, {scaleX:1, scaleY:1, alpha:1}, POUNCE);
			biteTooth.x = tooth.x + Layout.BOARD_BORDER;
			biteTooth.y = tooth.y + Layout.BOARD_BORDER;
		} else {
			biteToothJob = KTween.to(biteTooth, QUICK, {scaleX:0.5, scaleY:0.5, alpha:0, visible:false}, POUNCE, biteTooth.reset);
		}
	}
	
	private function firstBite(?event:Event):Void {
		if (draggingBite) return;
		draggingBite = true;
		var bX:Int = Std.int(grid.teeth.mouseX / Layout.UNIT_SIZE);
		var bY:Int = Std.int(grid.teeth.mouseY / Layout.UNIT_SIZE);
		if (!game.processPlayerAction(PlayerAction.START_BITE(bX, bY))) return;
		biteLimits = game.getBiteLimits();
	}
	
	private function dragBite(?snap:Bool):Void {
		
		var dX:Int = Std.int(biteTooth.mouseX / Layout.UNIT_SIZE);
		var dY:Int = Std.int(biteTooth.mouseY / Layout.UNIT_SIZE);
		var horiz:Bool = false;
		
		if (biteTooth.endX != 0) {
			horiz = true;
		} else if (biteTooth.endY != 0) {
			horiz = false;
		} else if (dY == 0) {
			horiz = true;
		} else if (dX == 0) {
			horiz = false;
		} else {
			horiz = Math.abs(dX) > Math.abs(dY);
		}
		
		var min:Int = horiz ? biteLimits[3] : biteLimits[0];
		var max:Int = horiz ? biteLimits[1] : biteLimits[2];
		var val:Int = horiz ? dX : dY;
		
		biteTooth.stretchTo(Std.int(Math.max(min, Math.min(val, max))), horiz);
	}
	
	private function endBite(?event:Event):Void {
		if (!draggingBite) return;
		draggingBite = false;
		if (biteToothJob != null) biteToothJob.complete();
		var pt:Point = grid.pattern.globalToLocal(biteTooth.localToGlobal(new Point()));
		var bX:Int = Std.int(pt.x / Layout.UNIT_SIZE) + biteTooth.endX;
		var bY:Int = Std.int(pt.y / Layout.UNIT_SIZE) + biteTooth.endY;
		if (biteTooth.endX != 0 || biteTooth.endY != 0 || !biteTooth.hitTestPoint(biteTooth.mouseX, biteTooth.mouseY)) {
			biteToothJob = KTween.to(biteTooth, QUICK, {scaleX:0.5, scaleY:0.5, alpha:0, visible:false}, POUNCE, biteTooth.reset);
		}
		if (game.processPlayerAction(PlayerAction.END_BITE(bX, bY))) {
			if (shiftBite && currentPlayer.bites > 0) {
				update(true, true, true);
				updateTeeth();
			} else {
				toggleBite(null, false);
				update(true, true, true);
			}
		}
	}
	
	private function cancelDragBite():Void {
		if (!draggingBite) return;
		draggingBite = false;
	}
	
	private function swapHint(event:Event):Void {
		if (draggingPiece || biting) return;
		if (swapCounterJob != null) swapCounterJob.complete();
		overSwapButton = event.type == MouseEvent.ROLL_OVER;
		if (overSwapButton) {
			swapHinting = true;
			piecePlug.visible = false;
			currentBlockForSwapHint = 0;
			pushCurrentSwapBlock();
			pieceHandle.filters = [PIECE_SWAP_GLOW];
			well.swapCounter.visible = true;
			well.swapCounter.alpha = 0;
			swapCounterJob = KTween.to(well.swapCounter, 3 * QUICK, {alpha:1}, POUNCE);
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
			piece.filters = [PIECE_GLOW];
			well.swapCounter.alpha = 1;
			swapCounterJob = KTween.to(well.swapCounter, 3 * QUICK, {alpha:0, visible:false}, POUNCE);
		}
	}
	
	private function pushCurrentSwapBlock():Void {
		if (!swapHinting) return;
		var block:Shape = pieceBlocks[currentBlockForSwapHint];
		var spotTaken:Bool;
		var spotX:Float = 0, spotY:Float = 0;
		while (true) {
			spotTaken = false;
			spotX = (Math.floor(Math.random() * 3) - 1.5 + pieceCenter[0]) * Layout.UNIT_SIZE;
			spotY = (Math.floor(Math.random() * 3) - 1.5 + pieceCenter[1]) * Layout.UNIT_SIZE;
			
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
		if (draggingPiece || !well.swapButton.mouseEnabled) return;
		toggleBite(null, false);
		swapHinting = false;
		game.processPlayerAction(PlayerAction.SWAP_PIECE);
		for (ike in 0...pieceBlocks.length) {
			if (pieceBlockJobs[ike] != null) pieceBlockJobs[ike].abort();
		}
		update(true);
		if (pieceRecipe == Pieces.O_PIECE) KTween.from(piecePlug, QUICK, {alpha:0}, POUNCE);
		if (!overSwapButton) {
			if (swapCounterJob != null) swapCounterJob.complete();
			well.swapCounter.visible = true;
			well.swapCounter.alpha = 1;
			swapCounterJob = KTween.to(well.swapCounter, 20 * QUICK, {alpha:0, visible:false}, Quad.easeIn);
		}
	}
	
	private function skipTurn(?event:Event):Void {
		if (draggingPiece || draggingBite) return;
		toggleBite(null, false);
		if (swapCounterJob != null) swapCounterJob.complete();
		game.processPlayerAction(PlayerAction.SKIP);
		currentPlayer = game.getCurrentPlayer();
		currentPlayerIndex = game.getCurrentPlayerIndex();
		update(true, true);
	}
}