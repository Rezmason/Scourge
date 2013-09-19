package view;

import flash.display.LineScaleMode;
import flash.display.Shape;
import flash.display.SimpleButton;
import flash.display.Sprite;
import flash.events.Event;
import flash.filters.GlowFilter;
import flash.geom.ColorTransform;
import flash.geom.Rectangle;
import flash.text.TextField;

import net.kawa.tween.KTJob;
import net.kawa.tween.easing.Linear;
import net.kawa.tween.easing.Quad;

using net.kawa.tween.KTween;

class TimerPanel extends Sprite {

	public var skipFunc:Void->Void;
	public var forfeitFunc:Void->Void;

	private static var PROGRESS_BAR_GLOW:GlowFilter = new GlowFilter(0xFFFFFF, 1, 7, 7, 20, 1, true);

	private var background:Shape;
	public var forfeitButton:SimpleButton;
	public var skipButton:SimpleButton;
	private var progressBar:Shape;

	private var progressBarJob:KTJob;
	private var duration:Float;

	public function new():Void {

		super();

		background = GUIFactory.drawSolidRect(new Shape(), 0x606060, 1, 0, 0, Layout.WELL_WIDTH, Layout.TIMER_PANEL_HEIGHT, Layout.BAR_CORNER_RADIUS);
		progressBar = new Shape();
		progressBar.filters = [PROGRESS_BAR_GLOW];
		skipButton = GUIFactory.makeButton(ScourgeLib_SkipSymbol, ScourgeLib_SkipButtonHitState, 1.3);
		forfeitButton = GUIFactory.makeButton(ScourgeLib_ForfeitSymbol, ScourgeLib_ForfeitButtonHitState, 1.3);

		forfeitButton.x = Layout.WELL_BORDER;
		forfeitButton.y = (Layout.TIMER_PANEL_HEIGHT - forfeitButton.height) / 2;
		skipButton.y = (Layout.TIMER_PANEL_HEIGHT - skipButton.height) / 2;
		skipButton.x = Layout.WELL_WIDTH - skipButton.width - Layout.WELL_BORDER;

		progressBar.graphics.lineStyle(Layout.TIMER_PANEL_HEIGHT / 2, 0x222222, 1, false, LineScaleMode.NONE);
		progressBar.graphics.moveTo(0, 0);
		progressBar.graphics.lineTo(Layout.WELL_WIDTH - skipButton.width - forfeitButton.x - forfeitButton.width - 5 * Layout.WELL_BORDER, 0);
		progressBar.x = forfeitButton.x + forfeitButton.width + 2 * Layout.WELL_BORDER;
		progressBar.y = Layout.TIMER_PANEL_HEIGHT / 2;

		GUIFactory.fillSprite(this, [
			background,
			progressBar,
			forfeitButton,
			skipButton
		]);
		GUIFactory.wireUp(skipButton, null, null, skip);
		GUIFactory.wireUp(forfeitButton, null, null, forfeit);
	}

	public function skip(?event:Event):Void { skipFunc(); }

	public function forfeit(?event:Event):Void { forfeitFunc(); }

	public function tint(ct:ColorTransform):Void {
		background.transform.colorTransform = ct;
		progressBar.transform.colorTransform = ct;
		skipButton.upState.transform.colorTransform = ct;
		forfeitButton.upState.transform.colorTransform = ct;
	}

	public function setDuration(time:Float):Void {
		duration = time;
		progressBar.visible = duration > 0;
	}

	public function reset():Void {
		var sX:Float = progressBar.scaleX;
		if (progressBarJob != null) progressBarJob.cancel();
		progressBar.scaleX = sX;
		progressBarJob = progressBar.to(0.2, {scaleX:1}, Quad.easeInOut, begin);
	}

	private function begin():Void {
		if (!progressBar.visible) return;
		progressBarJob = progressBar.to(duration, {width:1}, Linear.easeIn, skip);
	}
}
