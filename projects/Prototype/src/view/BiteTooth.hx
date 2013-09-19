package view;

import flash.display.CapsStyle;
import flash.display.LineScaleMode;
import flash.display.Shape;
import flash.display.Sprite;
import flash.filters.GlowFilter;
import flash.geom.ColorTransform;

class BiteTooth extends Sprite {

	private static var TOOTH_GLOW:GlowFilter = new GlowFilter(0xFFFFFF, 1, 7, 7, 1);
	private static var WHITE_CT:ColorTransform = new ColorTransform(1, 1, 1, 1, 0xFF, 0xFF, 0xFF);

	private var startTooth:Sprite;
	private var toothMiddle:Shape;
	private var endTooth:Sprite;

	public var endX:Int;
	public var endY:Int;

	public function new():Void {

		super();

		endX = endY = 0;

		startTooth = GUIFactory.makeTooth(Layout.UNIT_REZ * 1.2);
		toothMiddle = new Shape();
		endTooth = GUIFactory.makeTooth(Layout.UNIT_REZ * 1.2);

		GUIFactory.fillSprite(this, [startTooth, toothMiddle, endTooth]);

		visible = false;
		mouseEnabled = mouseChildren = false;
		transform.colorTransform = WHITE_CT;
		filters = [TOOTH_GLOW];
	}

	public function stretchTo(val:Int, horiz:Bool):Void {
		if (horiz) {
			endTooth.x = val * Layout.UNIT_REZ;
			endX = val;
		} else {
			endTooth.y = val * Layout.UNIT_REZ;
			endY = val;
		}
		toothMiddle.graphics.clear();
		toothMiddle.graphics.lineStyle(startTooth.width, 0xFFFFFF, 1, false, LineScaleMode.NORMAL, CapsStyle.NONE);
		toothMiddle.graphics.lineTo(endTooth.x, endTooth.y);
	}

	public function reset():Void {
		endTooth.x = endTooth.y = 0;
		endX = endY = 0;
		toothMiddle.graphics.clear();
	}
}
