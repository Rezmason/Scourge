package net.rezmason.scourge.flash;

import flash.display.CapsStyle;
import flash.display.LineScaleMode;
import flash.display.Shape;
import flash.display.Sprite;
import flash.filters.GlowFilter;
import flash.geom.ColorTransform;

import net.rezmason.scourge.Layout;

import flash.Lib;

class BiteTooth extends Sprite {
	
	private static var TOOTH_GLOW:GlowFilter = new GlowFilter(0xFFFFFF, 1, 7, 7, 1);
	private static var WHITE_CT:ColorTransform = new ColorTransform(1, 1, 1, 1, 0xFF, 0xFF, 0xFF);
	
	private var bt1:Sprite;
	private var body:Shape;
	private var bt2:Sprite;
	
	public var endX:Int;
	public var endY:Int;
	
	public function new():Void {
		
		super();
		
		endX = endY = 0;
		
		bt1 = GUIFactory.makeTooth(Layout.UNIT_SIZE * 1.2);
		body = new Shape();
		bt2 = GUIFactory.makeTooth(Layout.UNIT_SIZE * 1.2);
		
		GUIFactory.fillSprite(this, [bt1, body, bt2]);
		
		filters = [TOOTH_GLOW];
		visible = false;
		mouseEnabled = mouseChildren = false;
		transform.colorTransform = WHITE_CT;
		filters = [TOOTH_GLOW];
	}
	
	public function stretchTo(val:Int, horiz:Bool):Void {
		if (horiz) {
			bt2.x = val * Layout.UNIT_SIZE;
			endX = val;
		} else {
			bt2.y = val * Layout.UNIT_SIZE;
			endY = val;
		}
		body.graphics.clear();
		body.graphics.lineStyle(bt1.width, 0xFFFFFF, 1, null, LineScaleMode.NORMAL, CapsStyle.NONE);
		body.graphics.lineTo(bt2.x, bt2.y);
	}
	
	public function reset():Void {
		bt2.x = bt2.y = 0;
		endX = endY = 0;
		body.graphics.clear();
	}
}