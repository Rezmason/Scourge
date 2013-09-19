package view;

import flash.display.BlendMode;
import flash.display.Shape;
import flash.display.Sprite;
import flash.display.Stage;
import flash.display.StageScaleMode;
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.filters.GlowFilter;
import flash.geom.ColorTransform;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.ui.Keyboard;

import model.Game;
import Common;

import haxe.Timer;

import net.kawa.tween.KTJob;
import net.kawa.tween.easing.Linear;

using net.kawa.tween.KTween;

import flash.Lib;

class Board {

	inline static var __softSnap:Bool = true; // not sure if I want this

	inline static var MIN_WIDTH:Int = 400;
	inline static var MIN_HEIGHT:Int = 300;

	private static var PIECE_GLOW:GlowFilter = new GlowFilter(0xFFFFFF, 1, 7, 7, 20, 1, true);
	private static var PIECE_POP_GLOW:GlowFilter = new GlowFilter(0xFFFFFF, 1, 10, 10, 20, 1, true);
	private static var PIECE_SWAP_GLOW:GlowFilter = new GlowFilter(0xFFFFFF, 1, 10, 10, 4, 1);

	private static var PLAIN_CT:ColorTransform = GUIFactory.makeCT(0xFFFFFF);
	private static var ORIGIN:Point = new Point();

	private var options:Dynamic;
	private var game:Game;
	private var scene:Sprite;
	private var stage:Stage;

	private var background:Shape;
	private var grid:GameGrid;
	private var bar:Sprite;
	private var barBackground:Shape;
	private var well:Well;
	private var timerPanel:TimerPanel;
	private var statPanel:StatPanel;

	private var biting:Bool;
	private var draggingPiece:Bool;
	private var legalPiecePosition:Bool;
	private var shiftBite:Bool;
	private var swapHinting:Bool;
	private var waitingForGrid:Bool;
	private var overBiteButton:Bool;
	private var overSwapButton:Bool;
	private var playerCTs:Array<ColorTransform>;
	private var currentPlayerIndex:Int;
	private var currentPlayer:Player;
	private var keyList:Array<Bool>;
	private var box:Rectangle;
	private var lastGUIColorCycle:Int;
	private var guiColorJob:KTJob;
	private var guiColorTransform:ColorTransform;
	private var currentBlockForSwapHint:Int;

	private var boardSize:Int;
	private var boardNumCells:Int;

	private var piece:Sprite;
	private var pieceBlocks:Array<Shape>;
	private var piecePlug:Shape;
	private var pieceBite:Sprite;
	private var pieceHandle:Sprite;
	private var pieceWasOverGrid:Bool;
	private var pieceBoardScale:Float;
	private var pieceLocX:Int;
	private var pieceLocY:Int;
	private var pieceHomeX:Float;
	private var pieceHomeY:Float;
	private var pieceAngle:Int;
	private var pieceRecipe:Array<Int>;
	private var pieceCenter:Array<Float>;
	private var pieceHandleJob:KTJob;
	private var pieceHandleSpinJob:KTJob;
	private var pieceJob:KTJob;
	private var pieceBlockJobs:Array<KTJob>;
	private var pieceBiteJob:KTJob;
	private var handlePushTimer:Timer;

	private var stoicPiece:Shape;
	private var stoicPieceHandle:Sprite;

	public function new(__game:Game, __scene:Sprite, __options:GameOptions) {
		scene = __scene;
		game = __game;
		options = __options;
		scene.mouseEnabled = scene.mouseChildren = false;
		if (scene.stage != null) connectToStage();
		else scene.addEventListener(Event.ADDED_TO_STAGE, connectToStage);
	}

	private function connectToStage(?event:Event):Void {
		scene.removeEventListener(Event.ADDED_TO_STAGE, connectToStage);
		stage = scene.stage;
		stage.focus = stage;
		stage.scaleMode = StageScaleMode.NO_SCALE;
		initialize();
	}

	private function initialize():Void {

		// initialize the primitive variables
		draggingPiece = false;
		pieceWasOverGrid = false;
		swapHinting = false;
		biting = false;
		pieceBlockJobs = [];
		keyList = [];
		guiColorTransform = new ColorTransform(0, 0, 0);
		overSwapButton = false;
		overBiteButton = false;
		waitingForGrid = false;

		// create the player color transforms
		playerCTs = [];
		for (ike in 0...Common.TEAM_COLORS.length) playerCTs[ike] = GUIFactory.makeCT(Common.TEAM_COLORS[ike]);

		// build the scene
		background = GUIFactory.drawSolidRect(new Shape(), 0x0, 1, 0, 0, 800, 600);
		background.cacheAsBitmap = true;

		grid = new GameGrid();
		for (ike in 0...Common.MAX_PLAYERS) grid.makePlayerHeadAndBody();
		well = new Well();
		timerPanel = new TimerPanel();
		statPanel = new StatPanel();
		barBackground = GUIFactory.drawSolidRect(new Shape(), 0x333333, 1, 0, 0, Layout.BAR_WIDTH * 0.8, Layout.BAR_HEIGHT);
		barBackground.cacheAsBitmap = true;
		barBackground.visible = false;
		bar = GUIFactory.makeContainer([barBackground, timerPanel, statPanel, well]);

		well.rotateHint = rotateHint;
		well.rotatePiece = rotatePiece;
		well.biteHint = biteHint;
		well.toggleBite = toggleBite;
		well.swapHint = swapHint;
		well.swapPiece = swapPiece;
		timerPanel.skipFunc = skipTurn;
		timerPanel.forfeitFunc = forfeit;

		// position things
		well.x = well.y = Layout.BAR_MARGIN;
		timerPanel.x = Layout.BAR_MARGIN;
		timerPanel.y = well.y + Layout.WELL_WIDTH + Layout.BAR_MARGIN;
		statPanel.x = Layout.BAR_MARGIN;
		statPanel.y = timerPanel.y + Layout.TIMER_PANEL_HEIGHT + Layout.BAR_MARGIN;

		GUIFactory.fillSprite(scene, [background, grid, bar]);

		// Set up the piece, piece handle, piece blocks and piece bite
		pieceBlocks = [];
		var pBB:Float = Layout.PIECE_BLOCK_BORDER * Layout.UNIT_REZ;
		var bW:Float = Layout.UNIT_REZ + 2 * pBB;
		for (ike in 0...Common.MOST_BLOCKS_IN_PIECE + 1) pieceBlocks.push(GUIFactory.drawSolidRect(new Shape(), 0x222222, 1, -pBB, -pBB, bW, bW, bW * 0.5));
		piece = GUIFactory.makeContainer(pieceBlocks);
		piecePlug = GUIFactory.drawSolidRect(new Shape(), 0x222222, 1, 0, 0, bW, bW, bW);
		piecePlug.visible = false;
		piecePlug.x = piecePlug.y = Layout.UNIT_REZ / 2;
		piece.addChild(piecePlug);
		piece.filters = [PIECE_GLOW];
		pieceBite = new ScourgeLib_BiteMask();
		pieceBite.rotation = 180;
		pieceBite.visible = false;
		pieceBite.width = pieceBite.height = Layout.UNIT_REZ * 0.7;
		pieceBite.blendMode = BlendMode.ERASE;
		piece.addChild(pieceBite);
		piece.blendMode = BlendMode.LAYER;
		pieceHandle = well.pieceHandle;
		pieceHandle.addChild(piece);
		pieceHandle.tabEnabled = !(pieceHandle.buttonMode = pieceHandle.useHandCursor = true);
		pieceHandle.x = Layout.WELL_WIDTH  / 2;
		pieceHandle.y = Layout.WELL_WIDTH / 2;
		piece.scaleX = piece.scaleY = Layout.PIECE_SCALE;

		stoicPiece = new Shape();
		stoicPiece.scaleX = stoicPiece.scaleY = Layout.PIECE_SCALE;
		stoicPieceHandle = well.stoicPieceHandle;
		stoicPieceHandle.addChild(stoicPiece);

		// wire up the piece handle
		GUIFactory.wireUp(pieceHandle, popPieceOnRollover, popPieceOnRollover);

		// add events
		pieceHandle.addEventListener(MouseEvent.MOUSE_DOWN, liftPiece);
		grid.addEventListener(MouseEvent.MOUSE_DOWN, liftPiece);
		stage.addEventListener(MouseEvent.MOUSE_UP, dropPiece);
		grid.bite = takeBite;

		stage.addEventListener(Event.ADDED, resize, true);
		stage.addEventListener(Event.RESIZE, resize);
		stage.addEventListener(KeyboardEvent.KEY_DOWN, keyHandler);
		stage.addEventListener(KeyboardEvent.KEY_UP, keyHandler);
		stage.addEventListener(MouseEvent.MOUSE_MOVE, mouseHandler);

		// kick things off
		game.begin(options.numPlayers, GameType.CLASSIC, options.circular);
		timerPanel.setDuration(options.duration);
		boardSize = game.getBoardSize();
		currentPlayer = game.getCurrentPlayer();
		currentPlayerIndex = game.getCurrentPlayerIndex();
		lastGUIColorCycle = -1;
		grid.setSize(boardSize, game.getBoardNumCells(), options.circular);
		updateBox();
		grid.init(game.getPlayers(true), playerCTs);
		update(true, true);
		tweenGUIColors();
		scene.mouseEnabled = scene.mouseChildren = true;
		resize();
		fadeInGrid();
		//grid.fillBoardRandomly();
	}

	private function resize(?event:Event):Void {

		if (event != null && event.type == Event.ADDED && event.target != scene) return;

		var sw:Float = stage.stageWidth;
		var sh:Float = stage.stageHeight;

		sw = Math.max(sw, MIN_WIDTH);
		sh = Math.max(sh, MIN_HEIGHT);

		// size the background. This is more important later when I texture it
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
		bar.x = 0;
		bar.y = 0;

		var barWidth:Float = Layout.BAR_WIDTH * bar.scaleX;

		// scale and reposition grid
		if (sw - barWidth < sh) {
			grid.width = sw - barWidth - Layout.BAR_MARGIN * 2;
			grid.scaleY = grid.scaleX;
		} else {
			grid.height = sh - Layout.BAR_MARGIN * 2;
			grid.scaleX = grid.scaleY;
		}
		grid.x = barWidth + (sw - barWidth - grid.width) * 0.5;
		grid.y = (sh - grid.height) * 0.5;
	}

	private function keyHandler(event:KeyboardEvent):Void {
		var down:Bool = event.type == KeyboardEvent.KEY_DOWN;
		var wasDown:Bool = keyList[event.keyCode];
		if (down != wasDown) {
			switch (event.keyCode) {
				case Keyboard.SPACE: if (down) rotatePiece();
				case Keyboard.SHIFT, 65: // Firefox 4 bug
					if (event.charCode == 0 && event.shiftKey == down && !biting || shiftBite) {
						shiftBite = down;
						displayBite(down);
					}
				case Keyboard.TAB: if (down) swapPiece();
				case Keyboard.ESCAPE: if (down) skipTurn();
				case Keyboard.ENTER: if (down) forfeit();
				case Keyboard.F1: untyped __global__["flash.profiler.showRedrawRegions"](down);
				case Keyboard.F2:
					if (down) {
						var gridArr:Array<Int> = game.getBodyGrid();
						for (i in 0...gridArr.length) {
							if (gridArr[i] > 0) {

							} else {
								gridArr[i] = 0;
							}
						}
						Lib.trace(gridArr);
					}
				case 88: if (down) redoTurn();
				case 90: if (down) undoTurn();

			}
		}
		keyList[event.keyCode] = (event.type == KeyboardEvent.KEY_DOWN);
	}

	private function mouseHandler(event:MouseEvent):Void {
		if (draggingPiece) dragPiece(__softSnap);
	}

	private function updateBox():Void {
		box = new Rectangle(0, 0, boardSize * Layout.UNIT_REZ, boardSize * Layout.UNIT_REZ);
		box.inflate(Layout.UNIT_REZ, Layout.UNIT_REZ);
	}

	private function update(?thePiece:Bool, ?thePlay:Bool, ?fade:Bool, ?fadeByFreshness:Bool):Void {

		if (thePlay) {
			if (fade) {
				grid.fade(fadeByFreshness, game.getFreshGrid(true), game.getMaxFreshness());
				grid.addEventListener(Event.COMPLETE, gridUpdateResponder, false, 0, true);
				waitingForGrid = thePiece;
				pieceHandle.visible = false;
				lockScene();
			} else {
				cycleGUIColors();
			}
			grid.updateBodies(game.getBodyGrid(true));
			grid.updateHeads(game.getPlayers(true));
			timerPanel.reset();
			if (fade) return;
		}

		if (thePiece) {
			if (!biting) {
				pieceAngle = Std.int(Math.random() * 4);
				updatePiece();
				showPiece();
			}
			well.updateCounters(currentPlayer.swaps, currentPlayer.bites);
			well.updatePies(game.getSwapPhase(), game.getBitePhase());

			// Order the players by their turn and by whether they are alive
			var rollCall:Array<Player> = [];
			var players:Array<Player> = game.getPlayers(true);
			for (ike in currentPlayerIndex...players.length) if (players[ike].alive) rollCall.push(players[ike]);
			for (ike in 0...currentPlayerIndex) if (players[ike].alive) rollCall.push(players[ike]);
			for (ike in 0...players.length) if (!players[ike].alive) rollCall.push(players[ike]);

			statPanel.update(rollCall, playerCTs);
		}
	}

	private function gridUpdateResponder(event:Event):Void {
		grid.removeEventListener(Event.COMPLETE, gridUpdateResponder);
		cycleGUIColors();
		if (waitingForGrid) {
			waitingForGrid = false;
			update(true);
			unlockScene();
		}
	}

	private function lockScene():Void { scene.mouseChildren = false; }
	private function unlockScene():Void { scene.mouseChildren = true; }

	private function cycleGUIColors():Void {
		if (lastGUIColorCycle == currentPlayerIndex) return;
		lastGUIColorCycle = currentPlayerIndex;
		var tween:Dynamic = {};
		var ct:ColorTransform = playerCTs[currentPlayer.color];
		tween.redMultiplier = ct.redMultiplier;
		tween.greenMultiplier = ct.greenMultiplier;
		tween.blueMultiplier = ct.blueMultiplier;
		if (guiColorJob != null) guiColorJob.complete();
		guiColorJob = guiColorTransform.to(Layout.QUICK * 3, tween, Layout.SLIDE);
		guiColorJob.onChange = tweenGUIColors;
	}

	private function tweenGUIColors():Void {
		well.tint(guiColorTransform);
		grid.tint(guiColorTransform);
		statPanel.tint(guiColorTransform);
		timerPanel.tint(guiColorTransform);
		barBackground.transform.colorTransform = guiColorTransform;
	}

	private function updatePiece(?previousAngle:Int = 0):Void {

		// get the current mouse offsets;
		var c1X:Float = 0;
		var c1Y:Float = 0;
		var offX:Float = 0;
		var offY:Float = 0;
		var pt:Point;

		legalPiecePosition = false;

		if (pieceCenter != null) {
			c1X = Layout.UNIT_REZ * pieceCenter[0];
			c1Y = Layout.UNIT_REZ * pieceCenter[1];
			pt = stoicPiece.globalToLocal(stoicPieceHandle.localToGlobal(ORIGIN));
			offX = pt.x - c1X;
			offY = pt.y - c1Y;
			if (previousAngle > 0)		offX *= -1;
			else if (previousAngle < 0)	offY *= -1;
		}

		pieceRecipe = game.getPiece()[pieceAngle];
		pieceCenter = game.getPieceCenter()[pieceAngle];
		stoicPieceHandle.rotation = pieceHandle.rotation = 0;

		var c2X:Float = Layout.UNIT_REZ * pieceCenter[0];
		var c2Y:Float = Layout.UNIT_REZ * pieceCenter[1];

		// redraw the piece
		var ike:Int = 0, jen:Int = 0;
		while (jen < pieceBlocks.length) {
			var pieceBlock:Shape = pieceBlocks[jen];
			pieceBlock.x = Layout.UNIT_REZ * pieceRecipe[ike];
			pieceBlock.y = Layout.UNIT_REZ * pieceRecipe[ike + 1];
			if (ike + 2 < pieceRecipe.length) ike += 2;
			jen++;
		}

		// draw the piece's bounds to the stoic piece
		var pieceBounds:Rectangle = piece.getBounds(piece);
		stoicPiece.graphics.clear();
		stoicPiece.graphics.beginFill(0x0);
		stoicPiece.graphics.drawRect(pieceBounds.x, pieceBounds.y, pieceBounds.width, pieceBounds.height);
		stoicPiece.graphics.endFill();

		pieceBite.x = pieceRecipe[ike    ] * Layout.UNIT_REZ + pieceBlocks[jen - 1].width;
		pieceBite.y = pieceRecipe[ike + 1] * Layout.UNIT_REZ + pieceBlocks[jen - 1].height;
		piecePlug.visible = (pieceRecipe == Pieces.O_PIECE);

		// update the position
		pieceHomeX = -c2X * Layout.PIECE_SCALE;
		pieceHomeY = -c2Y * Layout.PIECE_SCALE;

		if (draggingPiece) {
			stoicPiece.x = 0;
			stoicPiece.y = 0;
			pt = stoicPiece.globalToLocal(stoicPieceHandle.localToGlobal(ORIGIN));
			stoicPiece.x = piece.x = (pt.x - c2X + offY) * Layout.PIECE_SCALE;
			stoicPiece.y = piece.y = (pt.y - c2Y + offX) * Layout.PIECE_SCALE;
			dragPiece(__softSnap);
		} else {
			stoicPiece.x = piece.x = pieceHomeX;
			stoicPiece.y = piece.y = pieceHomeY;
		}

		var lastAlpha:Float = pieceHandle.alpha;
		pieceHandle.transform.colorTransform = playerCTs[currentPlayer.color];
		pieceHandle.alpha = lastAlpha;

		enableDrag();
	}

	private function liftPiece(event:Event):Void {
		if (draggingPiece || biting) return;
		draggingPiece = true;
		pieceHandle.mouseEnabled = pieceHandle.mouseChildren = false;

		if (pieceHandleJob != null) pieceHandleJob.complete();
		if (pieceJob != null) pieceJob.complete();
		if (pieceHandleSpinJob != null) pieceHandleSpinJob.complete();

		pieceBoardScale = grid.scaleX / (Layout.PIECE_SCALE * stoicPieceHandle.scaleX * bar.scaleX);

		popPiece(true);

		var mX:Float, mY:Float;
		if (event.currentTarget == grid) {
			mX = pieceCenter[0];
			mY = pieceCenter[1];
		} else {
			mX = stoicPiece.mouseX / Layout.UNIT_REZ;
			mY = stoicPiece.mouseY / Layout.UNIT_REZ;
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

		var goodPt:Point = well.globalToLocal(stoicPiece.localToGlobal(new Point(goodX * Layout.UNIT_REZ, goodY * Layout.UNIT_REZ)));

		stoicPiece.x += stoicPieceHandle.x;
		stoicPiece.y += stoicPieceHandle.y;

		piece.x = stoicPiece.x;
		piece.y = stoicPiece.y;

		if (event.currentTarget == grid) {
			stoicPiece.x -= goodPt.x;
			stoicPiece.y -= goodPt.y;
			piece.x = stoicPiece.x;
			piece.y = stoicPiece.y;
			stoicPieceHandle.scaleX = stoicPieceHandle.scaleY = pieceBoardScale;
			pieceHandle.scaleX = pieceHandle.scaleY = pieceBoardScale;
		} else {
			stoicPiece.x -= goodPt.x;
			stoicPiece.y -= goodPt.y;
			piece.x -= well.mouseX;
			piece.y -= well.mouseY;
			pieceJob = piece.to(3 * Layout.QUICK, {x:stoicPiece.x, y:stoicPiece.y}, Layout.POUNCE);
			stoicPieceHandle.scaleX = stoicPieceHandle.scaleY = 1.2;
			pieceHandleJob = pieceHandle.to(Layout.QUICK, {scaleX:1.2, scaleY:1.2}, Linear.easeOut);
		}

		dragPiece(__softSnap, true);
	}

	private function dragPiece(?softSnap:Bool, ?shortcut:Bool):Void {

		if (!draggingPiece) return;

		var oldX:Float = stoicPieceHandle.x;
		var oldY:Float = stoicPieceHandle.y;

		var pieceOverGrid:Bool = box.contains(grid.space.mouseX, grid.space.mouseY);
		var scale:Float;

		// If the piece has moved onto or off of the grid, it needs to grow or shrink
		if (pieceOverGrid != pieceWasOverGrid) {
			pieceWasOverGrid = pieceOverGrid;
			if (pieceHandleJob != null) pieceHandleJob.complete();
			scale = pieceOverGrid ? pieceBoardScale : 1.2;
			stoicPieceHandle.scaleX = stoicPieceHandle.scaleY = scale;
			pieceHandleJob = pieceHandle.to(2 * Layout.QUICK, {scaleX:scale, scaleY:scale}, Linear.easeOut);
		}

		stoicPieceHandle.x = well.mouseX;
		stoicPieceHandle.y = well.mouseY;

		// If the piece is over the area of the grid where snapping should occur, it should snap
		if (pieceOverGrid) {

			var gp:Point = grid.space.globalToLocal(stoicPiece.localToGlobal(ORIGIN));

			var newPieceLocX:Int = Std.int(Math.round(gp.x / Layout.UNIT_REZ));
			var newPieceLocY:Int = Std.int(Math.round(gp.y / Layout.UNIT_REZ));

			if (pieceLocX == newPieceLocX && pieceLocY == newPieceLocY) {
				stoicPieceHandle.x = oldX;
				stoicPieceHandle.y = oldY;
			} else {

				pieceLocX = newPieceLocX;
				pieceLocY = newPieceLocY;

				legalPiecePosition = game.testPosition(pieceLocX, pieceLocY, pieceAngle);

				var gp2:Point = new Point(pieceLocX * Layout.UNIT_REZ, pieceLocY * Layout.UNIT_REZ);

				gp  = stoicPieceHandle.globalToLocal(grid.space.localToGlobal(gp));
				gp2 = stoicPieceHandle.globalToLocal(grid.space.localToGlobal(gp2));

				if (softSnap && shortcut) {
					pieceHandle.x = stoicPieceHandle.x;
					pieceHandle.y = stoicPieceHandle.y;
				}

				stoicPieceHandle.x += (gp2.x - gp.x) * stoicPieceHandle.scaleX;
				stoicPieceHandle.y += (gp2.y - gp.y) * stoicPieceHandle.scaleY;

				if (softSnap) {
					if (handlePushTimer == null) {
						handlePushTimer = new Timer(10);
						handlePushTimer.run = updateHandlePush;
					}
				} else {
					pieceHandle.x = stoicPieceHandle.x;
					pieceHandle.y = stoicPieceHandle.y;
				}
			}
		} else {
			pieceLocX = pieceLocY = -1;
			if (handlePushTimer != null) handlePushTimer.stop();
			handlePushTimer = null;
			pieceHandle.x = stoicPieceHandle.x;
			pieceHandle.y = stoicPieceHandle.y;
			legalPiecePosition = false;
		}

		pieceHandle.transform.colorTransform = legalPiecePosition ? PLAIN_CT : playerCTs[currentPlayer.color];
	}

	private function updateHandlePush():Void {
		if (!draggingPiece) return;
		pieceHandle.x = pieceHandle.x * (1 - Layout.GRID_SNAP_RATE) + stoicPieceHandle.x * Layout.GRID_SNAP_RATE;
		pieceHandle.y = pieceHandle.y * (1 - Layout.GRID_SNAP_RATE) + stoicPieceHandle.y * Layout.GRID_SNAP_RATE;
		if (stoicPieceHandle.x == pieceHandle.x && stoicPieceHandle.y == pieceHandle.y) finishHandlePush();
	}

	private function finishHandlePush():Void {
		if (!(draggingPiece && handlePushTimer != null)) return;
		if (handlePushTimer != null) handlePushTimer.stop();
		handlePushTimer = null;
	}

	private function dropPiece(?event:Event):Void {
		if (!draggingPiece) return;
		if (handlePushTimer != null) handlePushTimer.stop();
		handlePushTimer = null;

		dragPiece(false);

		pieceHandle.transform.colorTransform = playerCTs[currentPlayer.color];
		piece.filters = [PIECE_GLOW];
		pieceWasOverGrid = false;
		if (pieceHandleJob != null) pieceHandleJob.close();
		if (pieceJob != null) pieceJob.close();

		draggingPiece = false;

		if (pieceLocX != -1 && legalPiecePosition) {
			game.act(PlayerAction.PLACE_PIECE(pieceLocX, pieceLocY, pieceAngle));
			currentPlayer = game.getCurrentPlayer();
			currentPlayerIndex = game.getCurrentPlayerIndex();
			update(true, true, true, true);
		} else {
			pieceLocX = pieceLocY = -1;
			legalPiecePosition = false;
			var pieceHandleHome:Float = Layout.WELL_WIDTH / 2;
			stoicPieceHandle.x = stoicPieceHandle.y = pieceHandleHome;
			stoicPieceHandle.scaleX = stoicPieceHandle.scaleY = 1;
			stoicPiece.x = pieceHomeX;
			stoicPiece.y = pieceHomeY;
			pieceHandleJob = pieceHandle.to(2 * Layout.QUICK, {x:pieceHandleHome, y:pieceHandleHome, scaleX:1, scaleY:1}, Layout.POUNCE, enableDrag);
			pieceJob = piece.to(2 * Layout.QUICK, {x:pieceHomeX, y:pieceHomeY}, Layout.POUNCE);
		}
	}

	private function showPiece():Void {
		well.hideBiteIndicator();
		stoicPiece.x = piece.x = pieceHomeX;
		stoicPiece.y = piece.y = pieceHomeY;
		pieceHandle.visible = true;
		stoicPieceHandle.x = pieceHandle.x = Layout.WELL_WIDTH  / 2;
		stoicPieceHandle.y = pieceHandle.y = Layout.WELL_WIDTH / 2;
		stoicPieceHandle.scaleX = stoicPieceHandle.scaleY = pieceHandle.scaleX = pieceHandle.scaleY = 0.7;
		pieceHandle.alpha = 0;
		pieceHandle.mouseEnabled = pieceHandle.mouseChildren = false;
		if (pieceHandleJob != null) pieceHandleJob.close();
		if (pieceHandleSpinJob != null) pieceHandleSpinJob.complete();
		well.bringPieceHandleBackward();
		stoicPieceHandle.scaleX = stoicPieceHandle.scaleY = 1;
		pieceHandleJob = pieceHandle.to(3 * Layout.QUICK, {alpha:1, scaleX:1, scaleY:1}, Layout.SLIDE, enableDrag);
	}

	private function rotatePiece(?cc:Bool):Void {
		if (biting) return;
		finishHandlePush();
		if (pieceHandleSpinJob != null) pieceHandleSpinJob.complete();
		if (pieceJob != null) pieceJob.complete();

		pieceAngle += cc ? 1 : 3;
		pieceAngle %= 4;

		var turnAngle:Int = cc ? -90 : 90;
		updatePiece(turnAngle);

		pieceHandleSpinJob = pieceHandle.from(2 * Layout.QUICK, {rotation:-turnAngle}, Layout.POUNCE, enableDrag);

		if (!draggingPiece) {
			stoicPiece.x = pieceHomeX;
			stoicPiece.y = pieceHomeY;
			pieceJob = piece.to(2 * Layout.QUICK, {x:pieceHomeX, y:pieceHomeY}, Layout.POUNCE);
		}
		pieceHandle.mouseEnabled = pieceHandle.mouseChildren = false;
		if (pieceLocX != -1) legalPiecePosition = game.testPosition(pieceLocX, pieceLocY, pieceAngle);
		pieceHandle.transform.colorTransform = legalPiecePosition ? PLAIN_CT : playerCTs[currentPlayer.color];
	}

	private function enableDrag():Void {
		pieceHandle.mouseEnabled = pieceHandle.mouseChildren = true;
		well.bringPieceHandleForward();
	}

	private function popPieceOnRollover(event:Event):Void {
		if (draggingPiece) return;
		popPiece(event.type == MouseEvent.ROLL_OVER);
	}

	private function popPiece(?bigger:Bool):Void {
		piece.filters = [bigger ? PIECE_POP_GLOW : PIECE_GLOW];
	}

	private function toggleBite():Void { displayBite(!biting); }

	private function displayBite(?_biting:Bool):Void {
		if (draggingPiece || currentPlayer.bites < 1 && _biting) return;
		if (_biting) {
			well.showBiteIndicator(currentPlayer.biteSize, playerCTs[currentPlayer.color]);
			pieceHandle.visible = false;
			grid.showTeeth();
			grid.updateTeeth(game.getLegalBiteGrid(true), currentPlayerIndex, currentPlayer.headX, currentPlayer.headY, playerCTs[currentPlayer.color]);
			grid.tintTeeth(Common.TEAM_COLORS[currentPlayer.color]);
			if (!overBiteButton) well.displayBiteCounter(true);
		} else {
			if (biting) showPiece();
			grid.hideTeeth(currentPlayerIndex);
			pieceBite.visible = false;
			if (!overBiteButton && biting) well.displayBiteCounter(false);
		}
		biting = _biting;
	}

	private function takeBite(bSX:Int, bSY:Int, bEX:Int, bEY:Int):Void {
		game.act(PlayerAction.BITE(bSX, bSY, bEX, bEY));
		currentPlayer = game.getCurrentPlayer();
		currentPlayerIndex = game.getCurrentPlayerIndex();

		if (shiftBite && currentPlayer.bites > 0) {
			update(true, true, true, true);
			grid.updateTeeth(game.getLegalBiteGrid(true), currentPlayerIndex, currentPlayer.headX, currentPlayer.headY, playerCTs[currentPlayer.color]);
		} else {
			displayBite(false);
			update(true, true, true, true);
		}
	}

	private function swapPiece():Void {
		if (draggingPiece || currentPlayer.swaps < 1) return;
		displayBite(false);
		swapHinting = false;
		game.act(PlayerAction.SWAP_PIECE);
		currentPlayer = game.getCurrentPlayer();
		currentPlayerIndex = game.getCurrentPlayerIndex();

		for (ike in 0...pieceBlocks.length) if (pieceBlockJobs[ike] != null) pieceBlockJobs[ike].abort();
		update(true);
		if (pieceRecipe == Pieces.O_PIECE) piecePlug.from(Layout.QUICK, {alpha:0}, Layout.POUNCE);
		if (!overSwapButton) well.displaySwapCounter(false, true);
	}

	private function skipTurn():Void {
		if (draggingPiece || grid.isDraggingBite()) return;
		displayBite(false);
		well.displaySwapCounter(false);
		game.act(PlayerAction.SKIP);
		currentPlayer = game.getCurrentPlayer();
		currentPlayerIndex = game.getCurrentPlayerIndex();
		update(true, true);
	}

	private function forfeit():Void {
		if (draggingPiece || grid.isDraggingBite()) return;
		displayBite(false);
		game.act(PlayerAction.FORFEIT);
		currentPlayer = game.getCurrentPlayer();
		currentPlayerIndex = game.getCurrentPlayerIndex();
		update(true, true, true, true);
	}

	private function undoTurn(?event:Event):Void {
		if (!game.undoAction()) return;
		displayBite(false);
		currentPlayer = game.getCurrentPlayer();
		currentPlayerIndex = game.getCurrentPlayerIndex();
		update(true, true, true, false);
	}

	private function redoTurn(?event:Event):Void {
		if (!game.redoAction()) return;
		displayBite(false);
		currentPlayer = game.getCurrentPlayer();
		currentPlayerIndex = game.getCurrentPlayerIndex();
		update(true, true, true, false);
	}

	private function rotateHint(cc:Bool, over:Bool):Void {
		if (draggingPiece || biting) return;
		if (pieceHandleSpinJob != null) pieceHandleSpinJob.complete();
		var angle:Float = over ? (cc ? -10 : 10) : 0;
		pieceHandleSpinJob = pieceHandle.to(Layout.QUICK, {rotation:angle}, Layout.POUNCE);
	}

	private function biteHint(over:Bool):Void {
		if (draggingPiece || biting) return;

		if (pieceBiteJob != null) pieceBiteJob.complete();
		overBiteButton = over;
		if (overBiteButton) {
			pieceBite.visible = true;
			pieceBite.alpha = 1;
			var wham:Float = Layout.WELL_WIDTH * 0.05;
			//pieceHandle.rotation = 30;
			pieceHandleJob = pieceHandle.from(3 * Layout.QUICK, {x:pieceHandle.x + wham, y:pieceHandle.y + wham/*, rotation:0*/}, Layout.ZIGZAG);
		} else {
			pieceBite.alpha = 0.05;
			pieceBiteJob = pieceBite.to(3 * Layout.QUICK, {alpha:0, visible:false}, Layout.POUNCE);
			//pieceHandleJob = pieceHandle, 3 * Layout.QUICK, {rotation:0}.to(Layout.POUNCE);
		}
		well.displayBiteCounter(overBiteButton);
	}

	private function swapHint(over:Bool):Void {
		if (draggingPiece || biting) return;
		overSwapButton = over;
		if (overSwapButton) {
			swapHinting = true;
			piecePlug.visible = false;
			currentBlockForSwapHint = 0;
			pieceHandle.mouseEnabled = pieceHandle.mouseChildren = false;
			pushCurrentSwapBlock();
			pieceHandle.filters = [PIECE_SWAP_GLOW];
		} else {
			swapHinting = false;
			pieceHandle.mouseEnabled = pieceHandle.mouseChildren = true;
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
			piece.from(Layout.QUICK, {x:oldPieceX, y:oldPieceY}, Layout.POUNCE);
			for (ike in 0...pieceBlocks.length) pieceBlockJobs[ike] = pieceBlocks[ike].from(Layout.QUICK, {x:oldXs[ike], y:oldYs[ike]}, Layout.SLIDE);
			pieceHandle.filters = [];
			piece.filters = [PIECE_GLOW];
		}
		well.displaySwapCounter(over);
	}

	private function pushCurrentSwapBlock():Void {
		if (!swapHinting) return;
		var block:Shape = pieceBlocks[currentBlockForSwapHint];
		var spotTaken:Bool;
		var spotX:Float = 0, spotY:Float = 0;
		while (true) {
			spotTaken = false;
			spotX = (Math.floor(Math.random() * 3) - 1.5 + pieceCenter[0]) * Layout.UNIT_REZ;
			spotY = (Math.floor(Math.random() * 3) - 1.5 + pieceCenter[1]) * Layout.UNIT_REZ;

			for (ike in 0...pieceBlocks.length) {
				if (pieceBlockJobs[ike] != null) pieceBlockJobs[ike].abort();
				spotTaken = spotTaken || (pieceBlocks[ike].x == spotX && pieceBlocks[ike].y == spotY);
			}

			if (!spotTaken) break;
		}

		if (pieceBlockJobs[currentBlockForSwapHint] != null) pieceBlockJobs[currentBlockForSwapHint].close();
		pieceBlockJobs[currentBlockForSwapHint] = block.to(Layout.QUICK * 0.7, {x:spotX, y:spotY}, Linear.easeOut, pushCurrentSwapBlock);

		currentBlockForSwapHint = (currentBlockForSwapHint + 1) % pieceBlocks.length;
	}

	private function fadeInGrid():Void {
		var gridTween:Dynamic = {};
		gridTween.alpha = 1;
		grid.alpha = 0;
		grid.to(Layout.QUICK * 3, gridTween, Layout.SLIDE);
	}
}
