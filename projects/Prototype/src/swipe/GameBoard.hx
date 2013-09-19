package swipe;

import flash.display.Sprite;
import flash.display.Shape;
import flash.geom.ColorTransform;

using utils.display.FastDraw;

class GameBoard extends Sprite {

	private var bites:Shape;

	public function new():Void {
		super();
		bites = new Shape();
		addChild(bites);
		bites.drawBox(0xFF0000, 1, Layout.UNIT_REZ * 5, Layout.UNIT_REZ * 5, Layout.UNIT_REZ, Layout.UNIT_REZ);
		bites.visible = false;
	}

	public function setSize(_boardSize:Int, _boardNumCells:Int, ?circular:Bool):Void {
		clear().drawBox(0xFFFFFF, 1, 0, 0, _boardSize * Layout.UNIT_REZ, _boardSize * Layout.UNIT_REZ);
		drawBox(0x222222, 1, Layout.UNIT_REZ, Layout.UNIT_REZ, Layout.UNIT_REZ, Layout.UNIT_REZ);
	}

	public function init(players:Array<Player>, cts:Array<ColorTransform>):Void {

	}

	public function zoom(amt:Float):Void {
		scaleX = scaleY = amt;
	}

	public function showBites():Void {
		bites.visible = true;
	}

	public function hideBites():Void {
		bites.visible = false;
	}

}
