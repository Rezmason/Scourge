package net.rezmason.scourge.js;

import easeljs.Container;
import easeljs.Shape;
import easeljs.Text;

class TimerPanel extends Container {
	
	private var background:Shape;
	public var counter:Text;
	//public var skipButton:SimpleButton;
	
	public var skipFunc:Void->Void;
	
	
	public function new():Void {
		
		super();
		
		background = GUIFactory.drawSolidRect(new Shape(), 0x444444, 1, 0, 0, Layout.WELL_WIDTH, Layout.TIMER_HEIGHT, Layout.BAR_CORNER_RADIUS);
		/*
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
		*/
		
		GUIFactory.fillContainer(this, [background]);
	}
	
	public function tint(hx:Int):Void {
		
	}
	
}