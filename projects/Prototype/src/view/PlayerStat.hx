package view;

import flash.display.DisplayObject;
import flash.display.Shape;
import flash.display.Sprite;
import flash.geom.ColorTransform;
import flash.text.TextField;

import net.kawa.tween.KTJob;
import net.kawa.tween.easing.Quad;

using net.kawa.tween.KTween;

class PlayerStat extends Sprite {

	private static var DEAD_CT:ColorTransform = new ColorTransform(0.2, 0.2, 0.2);

	private var background:Shape;
	private var biteIcon1:Sprite;
	private var biteIcon2:Sprite;
	private var biteIcon3:Sprite;
	private var biteIcons:Sprite;
	private var txtName:TextField;
	private var txtBites:TextField;
	private var txtSwaps:TextField;
	private var tint:ColorTransform;

	private var tintJob:KTJob;
	private var shiftJob:KTJob;
	private var alive:Bool;
	private var biteIcon:DisplayObject;

	public var uid:Int;

	public function new(_uid:Int, hgt:Float):Void {
		super();

		alive = false;
		cacheAsBitmap = true;
		tint = new ColorTransform(0, 0, 0);
		updateTint();

		uid = _uid;
		background = GUIFactory.drawSolidRect(new Shape(), 0x606060, 1, 0, 0, Layout.WELL_WIDTH, hgt);
		biteIcon1 = new ScourgeLib_BiteIcon1(); biteIcon1.visible = false;
		biteIcon2 = new ScourgeLib_BiteIcon2(); biteIcon2.visible = false;
		biteIcon3 = new ScourgeLib_BiteIcon3(); biteIcon3.visible = false;
		biteIcons = GUIFactory.fillSprite(new Sprite(), [biteIcon1, biteIcon2, biteIcon3]);
		biteIcons.cacheAsBitmap = true;
		biteIcons.width = biteIcons.height = hgt * 0.6;
		biteIcons.x = biteIcons.y = hgt * 0.2;

		var w:Float = Layout.WELL_WIDTH - 3 * Layout.BAR_MARGIN - biteIcons.width;

		txtName = GUIFactory.makeTextBox(w * 0.6, hgt * 0.3, GUIFactory.MISO_FONT, 0.21 * w, 0xFFFFFF);
		txtBites = GUIFactory.makeTextBox(w * 0.4, hgt * 0.1, GUIFactory.MISO_FONT, 0.1 * w, 0xFFFFFF);
		txtSwaps = GUIFactory.makeTextBox(w * 0.4, hgt * 0.1, GUIFactory.MISO_FONT, 0.1 * w, 0xFFFFFF);

		txtName.x = biteIcons.x + biteIcons.width + 6;
		txtName.y = biteIcons.y - 3;

		txtBites.x = txtName.x + txtName.width;
		txtBites.y = txtName.y;

		txtSwaps.x = txtBites.x;
		txtSwaps.y = txtName.y + txtName.height;

		GUIFactory.fillSprite(this, [background, biteIcons, txtName, txtBites, txtSwaps]);
	}

	public function update(index:Int, player:Player, ct:ColorTransform):Void {
		if (player.alive != alive) {
			tintTo(player.alive ? ct : DEAD_CT);
			alive = player.alive;
		}

		if (biteIcon != null) biteIcon.visible = false;
		biteIcon = biteIcons.getChildAt(player.biteSize - 1);
		biteIcon.visible = true;

		txtName.text = player.name;
		txtBites.text = "BITES: " + Std.string(player.bites);
		txtSwaps.text = "SWAPS: " + Std.string(player.swaps);
		shiftTo(height * index);
	}

	private function tintTo(ct:ColorTransform):Void {
		if (tintJob != null) tintJob.complete();
		var tween:Dynamic = {};
		tween.redMultiplier = ct.redMultiplier;
		tween.greenMultiplier = ct.greenMultiplier;
		tween.blueMultiplier = ct.blueMultiplier;
		tintJob = tint.to(0.5, tween, Quad.easeInOut);
		tintJob.onChange = updateTint;
	}

	private function updateTint():Void {
		transform.colorTransform = tint;
	}

	private function shiftTo(newY:Float):Void {
		// tween to this new position
		if (shiftJob != null) shiftJob.close();
		shiftJob = this.to(0.2, {y:newY}, Quad.easeInOut);
	}
}
