/* defunct

package net.rezmason.scourge.flash;

import flash.display.Shape;
import flash.display.SimpleButton;
import flash.display.Sprite;
import flash.events.Event;
import flash.geom.ColorTransform;
import flash.geom.Rectangle;
import flash.text.TextField;

class TimerPanel extends Sprite {
	
	public var skipFunc:Void->Void;
	
	private var background:Shape;
	public var counter:TextField;
	public var skipButton:SimpleButton;
	
	public function new():Void {
		
		super();
		
		background = GUIFactory.drawSolidRect(new Shape(), 0x606060, 1, 0, 0, Layout.WELL_WIDTH, Layout.TIMER_HEIGHT, Layout.BAR_CORNER_RADIUS);
		
		counter = GUIFactory.makeTextBox(100, 30, GUIFactory.MISO, 28);
		counter.text = "0:00";
		skipButton = GUIFactory.makeButton(ScourgeLib_SkipSymbol, ScourgeLib_SkipButtonHitState, 1.3);
		
		var counterRect:Rectangle = counter.getCharBoundaries(0).union(counter.getCharBoundaries(counter.text.length - 1));
		
		counter.y = (Layout.TIMER_HEIGHT - counter.height) / 2 - counterRect.top;
		counter.x = Layout.WELL_BORDER;
		skipButton.y = (Layout.TIMER_HEIGHT - skipButton.height) / 2;
		skipButton.x = background.width - skipButton.width - Layout.WELL_BORDER;
		GUIFactory.fillSprite(this, [
			background, 
			counter, 
			skipButton
		]);
		GUIFactory.wireUp(skipButton, null, null, skip);
		
		counter.text = "---";
	}
	
	public function skip(event:Event):Void { skipFunc(); }
	
	public function tint(ct:ColorTransform):Void {
		background.transform.colorTransform = ct;
		counter.transform.colorTransform = ct;
		skipButton.upState.transform.colorTransform = ct;
	}
}

*/