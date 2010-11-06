package net.rezmason.scourge;

import flash.display.BlendMode;
import flash.display.MovieClip;
import flash.display.Shape;
import flash.display.SimpleButton;
import flash.display.Sprite;
import flash.geom.ColorTransform;
import flash.geom.Rectangle;
import flash.text.TextField;

class Well extends Sprite {
	
	private var background:Shape;
	public var rotateRightButton:SimpleButton;
	public var rotateLeftButton:SimpleButton;
	public var biteButton:SimpleButton;
	public var swapButton:SimpleButton;
	
	public var biteCounter:TextField;
	public var swapCounter:TextField;
	
	public var smallBiteIndicator:MovieClip;
	public var bigBiteIndicator:MovieClip;
	public var superBiteIndicator:MovieClip;
	
	public function new():Void {
		
		super();
		
		background = GUIFactory.drawSolidRect(new Shape(), 0x222222, 1, 0, 0, Layout.WELL_WIDTH, Layout.WELL_WIDTH, 40);
		
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
		
		swapCounter = GUIFactory.makeTextBox(100, 30, GUIFactory.MISO, 28);
		biteCounter = GUIFactory.makeTextBox(100, 30, GUIFactory.MISO, 28, 0xFFFFFF, true);
		
		smallBiteIndicator = new SmallTeeth();
		smallBiteIndicator.visible = false;
		smallBiteIndicator.blendMode = BlendMode.ADD;
		smallBiteIndicator.width = smallBiteIndicator.height = Layout.WELL_WIDTH - 40;
		smallBiteIndicator.x = smallBiteIndicator.y = 20;
		bigBiteIndicator = new BigTeeth();
		bigBiteIndicator.visible = false;
		bigBiteIndicator.blendMode = BlendMode.ADD;
		bigBiteIndicator.x = bigBiteIndicator.y = 20;
		bigBiteIndicator.width = bigBiteIndicator.height = Layout.WELL_WIDTH - 40;
		superBiteIndicator = new SuperTeeth();
		superBiteIndicator.visible = false;
		superBiteIndicator.blendMode = BlendMode.ADD;
		superBiteIndicator.x = superBiteIndicator.y = 20;
		superBiteIndicator.width = superBiteIndicator.height = Layout.WELL_WIDTH - 40;
		
		addChild(background);
		addChild(smallBiteIndicator); 
		addChild(bigBiteIndicator); 
		addChild(superBiteIndicator); 
		addChild(rotateRightButton); 
		addChild(rotateLeftButton); 
		addChild(swapCounter);
		addChild(biteCounter);
		addChild(swapButton); 
		addChild(biteButton);
		
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
	}
	
	public function tint(ct:ColorTransform):Void {
		background.transform.colorTransform = ct;
		rotateLeftButton.upState.transform.colorTransform = ct;
		rotateRightButton.upState.transform.colorTransform = ct;
		swapButton.upState.transform.colorTransform = ct;
		biteButton.upState.transform.colorTransform = ct;
		
		biteCounter.transform.colorTransform = ct;
		swapCounter.transform.colorTransform = ct;
	}
	
	public function updateCounters(swaps:Int, bites:Int):Void {
		swapCounter.alpha = swapButton.alpha = (swapButton.mouseEnabled = swaps > 0) ? 1 : 0.5;
		biteCounter.alpha = biteButton.alpha = (biteButton.mouseEnabled = bites > 0) ? 1 : 0.5;
		swapCounter.text = Std.string(swaps);
		biteCounter.text = Std.string(bites);
	}
}