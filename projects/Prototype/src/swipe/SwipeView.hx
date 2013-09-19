package swipe;

import flash.display.DisplayObject;
import flash.display.Sprite;
import flash.display.Shape;
import flash.display.Stage;
import flash.display.StageScaleMode;
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.geom.ColorTransform;
import flash.geom.Point;

import model.Game;
import Common;
import swipe.ContentType;
import swipe.Swipe;

import haxe.Timer;

import net.kawa.tween.KTJob;
import net.kawa.tween.easing.Linear;
import net.kawa.tween.easing.Quart;

import flash.Lib;

using Math;
using net.kawa.tween.KTween;
using utils.display.FastDraw;

class SwipeView {

	private static var ORIGIN:Point = new Point();

	private var gameBoard:GameBoard;

	private var options:GameOptions;
	private var game:Game;
	private var scene:Sprite;
	private var stage:Stage;

	private var playerCTs:Array<ColorTransform>;
	private var currentPlayerIndex:Int;
	private var currentPlayer:Player;
	private var keyList:Array<Bool>;
	private var lastGUIColorCycle:Int;
	private var guiColorJob:KTJob;
	private var guiColorTransform:ColorTransform;

	private var boardSize:Int;
	private var boardNumCells:Int;

	private var barWidth:Float;

	// Composition

	private var background:Sprite;
	private var board:GameBoard;
	private var swipeBar:Bar;

	private var piecePreview:Sprite;

	private var dropSwipe:Swipe;
	private var chopSwipe:Swipe;
	private var swapSwipe:Swipe;
	private var flopSwipe:Swipe;
	private var activeSwipe:Swipe;
	private var openSwipe:Swipe;

	private var actionBar:Bar;

	private var backButton:SwipeButton;
	//private var rotateSwitch:BlockySwitch;
	private var dropButton:SwipeButton;
	private var biteButton:SwipeButton;
	private var swapButton:SwipeButton;
	private var skipButton:SwipeButton;
	private var forfeitButton:SwipeButton;

	private var chopIcon:DisplayObject;
	private var swapIcon:DisplayObject;
	private var flopIcon:DisplayObject;

	private var boardZoom:Float;
	private var boardWidth:Float;
	private var boardCX:Float;
	private var boardCY:Float;
	private var panningBoard:Bool;
	private var boardPX:Float;
	private var boardPY:Float;
	private var boardMX:Float;
	private var boardMY:Float;
	private var boardMSX:Float;
	private var boardMSY:Float;
	private var boardPanSnapTween:{px:Float, py:Float};
	private var boardPanSnapJob:KTJob;
	private var boardZoneWidth:Float;
	private var boardZoneHeight:Float;

	private var dropUI:Array<DisplayObject>;
	private var chopUI:Array<DisplayObject>;
	private var swapUI:Array<DisplayObject>;
	private var flopUI:Array<DisplayObject>;

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

		// Basic data.
		keyList = [];

		// Display list composition.
		background = new Sprite();
		background.drawBox(0x0, 1, 0, 0, 1, 1);

		board = new GameBoard();
		panningBoard = false;
		boardZoom = 0;
		boardPX = boardPY = 0;
		setupBar();

		scene.pack([background, board, actionBar, swipeBar]);

		// Events.
		stage.addEventListener(Event.RESIZE, resize);
		stage.addEventListener(KeyboardEvent.KEY_DOWN, keyHandler);
		stage.addEventListener(KeyboardEvent.KEY_UP, keyHandler);
		scene.addEventListener(MouseEvent.ROLL_OVER, interruptMouseEvent, true);
		scene.addEventListener(MouseEvent.ROLL_OUT, interruptMouseEvent, true);
		scene.addEventListener(MouseEvent.CLICK, interruptMouseEvent, true);

		// kick things off
		game.begin(options.numPlayers, GameType.CLASSIC, options.circular);
		//timerPanel.setDuration(options.duration);
		boardSize = game.getBoardSize();
		currentPlayer = game.getCurrentPlayer();
		currentPlayerIndex = game.getCurrentPlayerIndex();
		lastGUIColorCycle = -1;
		board.setSize(boardSize, game.getBoardNumCells(), options.circular);
		board.init(game.getPlayers(true), playerCTs);
		//update(true, true);
		scene.mouseEnabled = scene.mouseChildren = true;
		resize();
	}

	private function setupBar():Void {

		swipeBar = new Bar();
		actionBar = new Bar();
		actionBar.autoLiftChildren = true;

		backButton = new SwipeButton(CAPTION("BACK"), goBack);
		//rotateSwitch = new BlockySwitch([CAPTION("CC"), CAPTION("C")], [function() rotate(true), function() rotate()]);
		dropButton = new SwipeButton(CAPTION("DROP"), dropPiece);
		biteButton = new SwipeButton(CAPTION("BITE"), takeBite);
		swapButton = new SwipeButton(CAPTION("SWAP"), swapPiece);
		skipButton = new SwipeButton(CAPTION("SKIP"), skipTurn);
		forfeitButton = new SwipeButton(CAPTION("DIE"), forfeit);

		dropUI = cast [
			new SwipeSpacer(1),		// not sure
			new SwipeSpacer(1),		//rotateSwitch
			dropButton,
			backButton,
		];

		chopUI = cast [
			new SwipeSpacer(2),		// bite indicator
			biteButton,
			backButton,
		];

		swapUI = cast [
			new SwipeSpacer(1), 	// piece indicator
			new SwipeSpacer(1), 	// swap count indicator
			swapButton,
			backButton,
		];

		flopUI = cast [
			new SwipeSpacer(1),		// not sure
			skipButton,
			forfeitButton,
			backButton,
		];

		// TODO: icons for buttons

		var swipeHandlers:SwipeInitObject = {
			grab:handleSwipeGrab,
			drop:handleSwipeDrop,
			drag:handleSwipeDrag,
			hint:handleSwipeHint,
		};

		dropSwipe = new Swipe("DROP", CAPTION("PLACE\nPIECE"), dropUI, swipeHandlers);
		chopSwipe = new Swipe("BITE", CAPTION("TAKE\nBITE"), chopUI, swipeHandlers);
		swapSwipe = new Swipe("SWAP", CAPTION("SWAP\nPIECE"), swapUI, swipeHandlers);
		flopSwipe = new Swipe("SKIP", CAPTION("SKIP\nTURN"), flopUI, swipeHandlers);

		swipeBar.contents = cast [dropSwipe, chopSwipe, swapSwipe, flopSwipe];
	}

	private function resize(?event:Event):Void {

		if (event != null && event.type == Event.ADDED && event.target != scene) return;

		var sw:Float = stage.stageWidth;
		var sh:Float = stage.stageHeight;

		sw = sw.max(Layout.MIN_WIDTH);
		sh = sh.max(Layout.MIN_HEIGHT);

		// size the background. This is more important later when I texture it

		barWidth = Layout.BAR_WIDTH * sh / Layout.NATIVE_HEIGHT;

		background.scaleX = background.scaleY = 1;
		var bw:Float = sw + barWidth;
		if (background.width / background.height < bw / sh) {
			background.width = bw;
			background.scaleY = background.scaleX;
		} else {
			background.height = sh;
			background.scaleX = background.scaleY;
		}

		swipeBar.x = 0;
		swipeBar.y = 0;

		actionBar.x = sw;
		actionBar.y = 0;

		dropSwipe.resizeTrack(sw + barWidth);
		chopSwipe.resizeTrack(sw + barWidth);
		swapSwipe.resizeTrack(sw + barWidth);
		flopSwipe.resizeTrack(sw + barWidth);

		swipeBar.resize(barWidth, sh);
		actionBar.resize(barWidth, sh);

		// scale and reposition board
		boardZoneWidth = sw - barWidth;
		boardZoneHeight = sh;
		boardWidth = boardZoneHeight.min(boardZoneWidth) - Layout.BOARD_MARGIN * 2;
		boardCX = barWidth + (sw - barWidth) * 0.5;
		boardCY = sh * 0.5;
		updateBoard();
	}

	private function interruptMouseEvent(event:MouseEvent):Void {
		if (activeSwipe != null && activeSwipe != event.target && !activeSwipe.contains(event.target)) {
			event.stopImmediatePropagation();
		}
	}

	private function keyHandler(event:KeyboardEvent):Void {
		var down:Bool = event.type == KeyboardEvent.KEY_DOWN;
		var wasDown:Bool = keyList[event.keyCode];
		if (down != wasDown) {
			/*
			switch (event.keyCode) {

			}
			*/
		}

		keyList[event.keyCode] = (event.type == KeyboardEvent.KEY_DOWN);
	}

	private function handleSwipeGrab(swipe:Swipe):Void {
		if (activeSwipe == null) activeSwipe = swipe;
	}

	private function handleSwipeDrop(swipe:Swipe):Void {
		if (activeSwipe == swipe) activeSwipe = null;
	}

	private function handleSwipeDrag(swipe:Swipe, percent:Float):Void {

		if (swipe != activeSwipe) return;

		scene.x = percent * -barWidth;

		if (percent >= 1) {
			openSwipe = activeSwipe;
			actionBar.expandFromSwipe(openSwipe);
		}

		// Special treatment for swipes whose actions involve unique board interaction
		if (swipe == chopSwipe) {
			boardZoom = percent;
			updateBoard();
			if (percent >= 1) {
				enableBoardPanning();
			} else {
				disableBoardPanning();
				if (percent <= 0) {
					boardPX = boardPY = 0;
				}
			}
		}
	}

	private function handleSwipeHint(swipe:Swipe, hinting:Bool):Void {
		if (swipe == chopSwipe) {
			if (hinting)  {
				board.showBites();
			} else {
				board.hideBites();
			}
		}

		if (hinting) {
			swipeBar.liftChild(swipe);
		} else {
			swipeBar.dropChild(swipe);
		}
	}

	private function goBack():Void {
		if (openSwipe != null) {
			openSwipe.show(true);
			actionBar.collapseToSwipe(openSwipe);
			openSwipe = null;
		}
	}

	private function dropPiece():Void {
		Lib.trace("DROP PIECE");
		goBack();
	}

	private function takeBite():Void {
		Lib.trace("TAKE BITE");
	}

	private function swapPiece():Void {
		Lib.trace("SWAP PIECE");
	}

	private function skipTurn():Void {
		Lib.trace("SKIP TURN");
		goBack();
	}

	private function forfeit():Void {
		Lib.trace("FORFEIT");
		goBack();
	}

	private function updateBoard():Void {
		board.width = board.height = boardWidth * (1 + boardZoom * Layout.BITE_ZOOM);
		board.x = boardCX - board.width * 0.5 + boardPX * boardZoom;
		board.y = boardCY - board.width * 0.5 + boardPY * boardZoom;
	}

	private function enableBoardPanning():Void {
		board.addEventListener(MouseEvent.MOUSE_DOWN, beginBoardPan);
		background.addEventListener(MouseEvent.MOUSE_DOWN, beginBoardPan);
	}

	private function disableBoardPanning():Void {
		endBoardPan();
		board.removeEventListener(MouseEvent.MOUSE_DOWN, beginBoardPan);
		background.removeEventListener(MouseEvent.MOUSE_DOWN, beginBoardPan);
	}

	private function beginBoardPan(event:Event):Void {

		if (panningBoard) return;
		panningBoard = true;

		if (boardPanSnapJob != null) boardPanSnapJob.close();

		stage.addEventListener(MouseEvent.MOUSE_MOVE, updateBoardPan);
		stage.addEventListener(MouseEvent.MOUSE_UP, endBoardPan);
		stage.addEventListener(Event.MOUSE_LEAVE, endBoardPan);

		boardMSX = boardPX;
		boardMSY = boardPY;
		boardMX = scene.mouseX;
		boardMY = scene.mouseY;
	}

	private function updateBoardPan(event:Event):Void {
		boardPX = boardMSX + scene.mouseX - boardMX;
		boardPY = boardMSY + scene.mouseY - boardMY;
		updateBoard();
	}

	private function endBoardPan(?event:Event):Void {

		if (!panningBoard) return;
		panningBoard = false;

		stage.removeEventListener(MouseEvent.MOUSE_MOVE, updateBoardPan);
		stage.removeEventListener(MouseEvent.MOUSE_UP, endBoardPan);
		stage.removeEventListener(Event.MOUSE_LEAVE, endBoardPan);

		var lw:Float = (board.width - boardZoneWidth  ) * 0.5 + Layout.BOARD_ZOOM_PAN_MARGIN;
		var lh:Float = (board.width - boardZoneHeight ) * 0.5 + Layout.BOARD_ZOOM_PAN_MARGIN;
		var goalPX:Float = boardPX.min(lw).max(-lw);
		var goalPY:Float = boardPY.min(lh).max(-lh);

		if (goalPX != boardPX || goalPY != boardPY) {
			boardPanSnapTween = {px:boardPX, py:boardPY};
			boardPanSnapJob = boardPanSnapTween.to(0.25, {px:goalPX, py:goalPY}, Quart.easeOut);
			boardPanSnapJob.onChange = updateBoardSnapTween;
		}
	}

	private function updateBoardSnapTween():Void {
		boardPX = boardPanSnapTween.px;
		boardPY = boardPanSnapTween.py;
		updateBoard();
	}
}
