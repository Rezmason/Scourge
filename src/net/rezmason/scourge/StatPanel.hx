package net.rezmason.scourge;

import flash.display.Shape;
import flash.display.Sprite;
import flash.geom.ColorTransform;

class StatPanel extends Sprite {
	
	private var background:Shape;
	
	public function new(hgt:Float):Void {
		super();
		background = GUIFactory.drawSolidRect(new Shape(), 0x222222, 1, 0, 0, 210, hgt, 40);
		GUIFactory.fillSprite(this, [background]);
	}
	
	public function tint(ct:ColorTransform):Void {
		background.transform.colorTransform = ct;
	}
}