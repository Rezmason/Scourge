package view;

import flash.display.BlendMode;
import flash.display.MovieClip;
import flash.display.Shape;
import flash.display.SimpleButton;
import flash.display.Sprite;
import flash.events.MouseEvent;
import flash.geom.ColorTransform;
import flash.geom.Rectangle;
import flash.text.TextField;

import utils.display.Pie;

import net.kawa.tween.KTJob;
import net.kawa.tween.easing.Quad;

using net.kawa.tween.KTween;

class Well extends Sprite {

	public var rotateHint:Bool->Bool->Void;
	public var rotatePiece:Bool->Void;
	public var biteHint:Bool->Void;
	public var toggleBite:Void->Void;
	public var swapHint:Bool->Void;
	public var swapPiece:Void->Void;

	public var pieceHandle:Sprite;
	public var stoicPieceHandle:Sprite;

	private var background:Shape;
	private var rotateRightButton:SimpleButton;
	private var rotateLeftButton:SimpleButton;
	private var biteButton:SimpleButton;
	private var swapButton:SimpleButton;
	private var biteCounter:TextField;
	private var swapCounter:TextField;
	private var swapCounterJob:KTJob;
	private var biteCounterJob:KTJob;

	private var smallBiteIndicator:MovieClip;
	private var bigBiteIndicator:MovieClip;
	private var superBiteIndicator:MovieClip;
	private var biteIndicators:Sprite;
	private var currentBiteIndicator:MovieClip;

	private var bitePie:Pie;
	private var swapPie:Pie;

	public function new():Void {

		super();

		var w:Float = Layout.WELL_WIDTH;
		var rad:Float = w / Math.sqrt(3);

		background = GUIFactory.drawSolidRect(new Shape(), 0x606060, 1, 0, 0, Layout.WELL_WIDTH, Layout.WELL_WIDTH, Layout.BAR_CORNER_RADIUS);
		//background = GUIFactory.drawSolidPoly(new Shape(), 0x606060, 1, 6, w / 2, rad / 2, rad, 30, Layout.BAR_CORNER_RADIUS);

		background.cacheAsBitmap = true;
		rotateRightButton = GUIFactory.makeButton(ScourgeLib_RotateSymbol, ScourgeLib_WellButtonHitState, 1.5, 180, true);
		rotateLeftButton = GUIFactory.makeButton(ScourgeLib_RotateSymbol, ScourgeLib_WellButtonHitState, 1.5, 270);
		biteButton = GUIFactory.makeButton(ScourgeLib_BiteSymbol, ScourgeLib_WellButtonHitState, 1.5, 180);
		swapButton = GUIFactory.makeButton(ScourgeLib_SwapSymbol, ScourgeLib_WellButtonHitState, 1.5);

		rotateLeftButton.y = Layout.WELL_WIDTH - Layout.WELL_BORDER;
		rotateLeftButton.x = Layout.WELL_BORDER;
		rotateRightButton.y = Layout.WELL_BORDER;
		rotateRightButton.x = Layout.WELL_WIDTH - Layout.WELL_BORDER;
		swapButton.x = Layout.WELL_BORDER;
		swapButton.y = Layout.WELL_BORDER;
		biteButton.x = Layout.WELL_WIDTH - Layout.WELL_BORDER;
		biteButton.y = Layout.WELL_WIDTH - Layout.WELL_BORDER;
		swapCounter = GUIFactory.makeTextBox(50, 30, GUIFactory.MISO_FONT, 28);
		biteCounter = GUIFactory.makeTextBox(50, 30, GUIFactory.MISO_FONT, 28, 0xFFFFFF, true);
		bitePie = new Pie(8, 0xCCCCCC, 0x808080);
		swapPie = new Pie(8, 0xCCCCCC, 0x808080);

		biteIndicators = new Sprite();

		smallBiteIndicator = new SmallTeeth();
		smallBiteIndicator.visible = false;
		smallBiteIndicator.width = smallBiteIndicator.height = Layout.WELL_WIDTH - 40;
		smallBiteIndicator.x = smallBiteIndicator.y = 20;
		bigBiteIndicator = new BigTeeth();
		bigBiteIndicator.visible = false;
		bigBiteIndicator.x = bigBiteIndicator.y = 20;
		bigBiteIndicator.width = bigBiteIndicator.height = Layout.WELL_WIDTH - 40;
		superBiteIndicator = new SuperTeeth();
		superBiteIndicator.visible = false;
		superBiteIndicator.x = superBiteIndicator.y = 20;
		superBiteIndicator.width = superBiteIndicator.height = Layout.WELL_WIDTH - 40;

		biteIndicators.blendMode = BlendMode.ADD;
		biteIndicators.soundTransform = new flash.media.SoundTransform(0); // for now
		GUIFactory.fillSprite(biteIndicators, [smallBiteIndicator, bigBiteIndicator, superBiteIndicator]);

		pieceHandle = new Sprite();
		stoicPieceHandle = new Sprite();
		stoicPieceHandle.visible = false;

		GUIFactory.fillSprite(this, [
			background,
			pieceHandle,
			stoicPieceHandle,
			biteIndicators,
			rotateRightButton,
			rotateLeftButton,
			swapButton,
			biteButton,
			swapCounter,
			biteCounter,
			swapPie,
			bitePie,
		]);
		biteCounter.text = "888";
		swapCounter.text = "888";

		var swapCounterRect:Rectangle = swapCounter.getCharBoundaries(0).union(swapCounter.getCharBoundaries(biteCounter.text.length - 1));
		var biteCounterRect:Rectangle = biteCounter.getCharBoundaries(0).union(biteCounter.getCharBoundaries(swapCounter.text.length - 1));
		var swapButtonRect:Rectangle = swapButton.getBounds(this);
		var biteButtonRect:Rectangle = biteButton.getBounds(this);

		swapCounter.x = swapButtonRect.right + 5 - swapCounterRect.left;
		swapCounter.y = swapButtonRect.top - swapCounterRect.top;
		biteCounter.x = biteButtonRect.left - 5 - biteCounterRect.right;
		biteCounter.y = biteButtonRect.bottom - biteCounterRect.bottom;
		biteCounter.text = "0";
		swapCounter.text = "0";
		biteCounter.visible = false;
		swapCounter.visible = false;

		swapPie.x = swapButtonRect.left + swapPie.radius;
		swapPie.y = (swapButtonRect.bottom + 10 + swapPie.radius);
		swapPie.rotation = -90;

		bitePie.x = biteButtonRect.right - bitePie.radius;
		bitePie.y = (biteButtonRect.top - 10 - bitePie.radius);
		bitePie.rotation = -90;

		GUIFactory.wireUp(rotateRightButton, hint, hint, click);
		GUIFactory.wireUp(rotateLeftButton, hint, hint, click);
		GUIFactory.wireUp(biteButton, hint, hint, click);
		GUIFactory.wireUp(swapButton, hint, hint, click);
	}

	public function tint(ct:ColorTransform):Void {
		background.transform.colorTransform = ct;
		rotateLeftButton.upState.transform.colorTransform = ct;
		rotateRightButton.upState.transform.colorTransform = ct;
		swapButton.upState.transform.colorTransform = ct;
		biteButton.upState.transform.colorTransform = ct;
		biteCounter.transform.colorTransform = ct;
		swapCounter.transform.colorTransform = ct;
		bitePie.transform.colorTransform = ct;
		swapPie.transform.colorTransform = ct;
	}

	public function bringPieceHandleForward():Void { addChild(pieceHandle); }
	public function bringPieceHandleBackward():Void { addChildAt(pieceHandle, 1); }

	public function updateCounters(swaps:Int, bites:Int):Void {
		if (swapCounterJob != null) swapCounterJob.complete();
		if (biteCounterJob != null) biteCounterJob.complete();
		swapCounter.alpha = swapButton.alpha = (swapButton.mouseEnabled = swaps > 0) ? 1 : 0.5;
		biteCounter.alpha = biteButton.alpha = (biteButton.mouseEnabled = bites > 0) ? 1 : 0.5;
		swapCounter.text = Std.string(swaps);
		biteCounter.text = Std.string(bites);
	}

	public function updatePies(swapFraction:Float, biteFraction:Float):Void {
		swapPie.fraction = swapFraction;
		swapPie.redraw();
		bitePie.fraction = biteFraction;
		bitePie.redraw();
	}

	public function showBiteIndicator(index:Int, ct:ColorTransform):Void {
		currentBiteIndicator = cast(biteIndicators.getChildAt(index - 1), MovieClip);
		currentBiteIndicator.visible = true;
		currentBiteIndicator.gotoAndPlay("in");
		biteIndicators.transform.colorTransform = offsetCT(ct, 0.2);
	}

	public function hideBiteIndicator():Void {
		if (currentBiteIndicator != null) {
			currentBiteIndicator.gotoAndStop(0);
			currentBiteIndicator.visible = false;
			currentBiteIndicator = null;
		}
	}

	public function displayBiteCounter(show:Bool):Void {
		if (biteCounterJob != null) biteCounterJob.complete();
		biteCounter.visible = true;
		biteCounter.alpha = show ? 0 : 1;
		biteCounterJob = biteCounter.to(3 * Layout.QUICK, {alpha:(show ? 1 : 0), visible:show}, Layout.POUNCE);
	}

	public function displaySwapCounter(show:Bool, ?slowly:Bool):Void {
		if (swapCounterJob != null) swapCounterJob.complete();
		swapCounter.visible = true;
		swapCounter.alpha = show ? 0 : 1;
		swapCounterJob = swapCounter.to((slowly ? 3 : 3 * Layout.QUICK), {alpha:(show ? 1 : 0), visible:show}, (slowly ? Quad.easeOut : Layout.POUNCE));
	}

	private function hint(event:MouseEvent):Void {
		var over:Bool = event.type == MouseEvent.ROLL_OVER;
		if (false) false;
		else if (event.currentTarget == rotateLeftButton) rotateHint(true, over);
		else if (event.currentTarget == rotateRightButton) rotateHint(false, over);
		else if (event.currentTarget == biteButton) biteHint(over);
		else if (event.currentTarget == swapButton) swapHint(over);
	}

	private function click(event:MouseEvent):Void {
		if (false) false;
		else if (event.currentTarget == rotateLeftButton) rotatePiece(true);
		else if (event.currentTarget == rotateRightButton) rotatePiece(false);
		else if (event.currentTarget == biteButton) toggleBite();
		else if (event.currentTarget == swapButton) swapPiece();
	}

	private static function offsetCT(ct:ColorTransform, mult:Float):ColorTransform {
		var red:Int = Std.int(ct.redMultiplier * 0xFF * mult);
		var green:Int = Std.int(ct.greenMultiplier * 0xFF * mult);
		var blue:Int = Std.int(ct.blueMultiplier * 0xFF * mult);
		return new ColorTransform(1, 1, 1, 1, red, green, blue);
	}

}
