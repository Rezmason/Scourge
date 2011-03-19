package net.rezmason.scourge.js;

import easeljs.Container;
import easeljs.Shape;

import net.rezmason.scourge.Layout;

class BiteTooth extends Container {
	/*
	private static var TOOTH_GLOW:GlowFilter = new GlowFilter(0xFFFFFF, 1, 7, 7, 1);
	private static var WHITE_CT:ColorTransform = new ColorTransform(1, 1, 1, 1, 0xFF, 0xFF, 0xFF);
	*/
	
	private var startTooth:Container;
	private var toothMiddle:Shape;
	private var endTooth:Container;
	
	public var endX:Int;
	public var endY:Int;
	
	public function new():Void {
		
		super();
		
		endX = endY = 0;
		
		startTooth = GUIFactory.makeTooth(Layout.UNIT_SIZE * 1.2);
		toothMiddle = new Shape();
		endTooth = GUIFactory.makeTooth(Layout.UNIT_SIZE * 1.2);
		
		GUIFactory.fillContainer(this, [startTooth, toothMiddle, endTooth]);
		
		visible = false;
		mouseEnabled = false;
		//transform.colorTransform = WHITE_CT;
		//filters = [TOOTH_GLOW];
	}
	
	public function stretchTo(val:Int, horiz:Bool):Void {
		if (horiz) {
			endTooth.x = val * Layout.UNIT_SIZE;
			endX = val;
		} else {
			endTooth.y = val * Layout.UNIT_SIZE;
			endY = val;
		}
		
		toothMiddle.graphics.clear().setStrokeStyle(Layout.UNIT_SIZE * 1.2).beginStroke(GUIFactory.colorString(0xFFFFFF)).lineTo(endTooth.x, endTooth.y).endFill();
	}
	
	public function reset():Void {
		endTooth.x = endTooth.y = 0;
		endX = endY = 0;
		toothMiddle.graphics.clear();
	}
}