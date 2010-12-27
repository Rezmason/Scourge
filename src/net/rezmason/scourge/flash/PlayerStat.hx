package net.rezmason.scourge.flash;

import flash.display.DisplayObject;
import flash.display.Shape;
import flash.display.Sprite;
import flash.geom.ColorTransform;
import flash.text.TextField;

import net.kawa.tween.KTJob;
import net.kawa.tween.KTween;
import net.kawa.tween.easing.Quad;

import net.rezmason.scourge.Player;
import net.rezmason.scourge.Layout;

import flash.Lib;

class PlayerStat extends Sprite {
	
	private static var DEAD_CT:ColorTransform = new ColorTransform(0.5, 0.5, 0.5);
	
	private var background:Shape;
	private var biteIcon1:Sprite;
	private var biteIcon2:Sprite;
	private var biteIcon3:Sprite;
	private var biteIcons:Sprite;
	private var txtName:TextField;
	private var txtData:TextField;
	private var tint:ColorTransform;
	
	private var tintJob:KTJob;
	private var shiftJob:KTJob;
	private var alive:Bool;
	private var biteIcon:DisplayObject;
	
	public var id:Int;
	
	public function new(_id:Int, hgt:Float):Void {
		super();
		
		alive = false;
		cacheAsBitmap = true;
		tint = new ColorTransform();
		
		id = _id;
		background = GUIFactory.drawSolidRect(new Shape(), 0x444444, 1, 0, 0, 210, hgt);
		biteIcon1 = new ScourgeLib_BiteIcon1(); biteIcon1.visible = false;
		biteIcon2 = new ScourgeLib_BiteIcon2(); biteIcon2.visible = false;
		biteIcon3 = new ScourgeLib_BiteIcon3(); biteIcon3.visible = false;
		biteIcons = GUIFactory.fillSprite(new Sprite(), [biteIcon1, biteIcon2, biteIcon3]);
		biteIcons.cacheAsBitmap = true;
		biteIcons.width = biteIcons.height = hgt * 0.6;
		biteIcons.x = biteIcons.y = hgt * 0.2;
		txtName = GUIFactory.makeTextBox(210 - 3 * Layout.BAR_MARGIN - biteIcons.width, hgt * 0.4, GUIFactory.MISO, 28, 0xFFFFFF);
		txtData = GUIFactory.makeTextBox(210 - 2 * Layout.BAR_MARGIN, hgt * 0.3, GUIFactory.MISO, 18, 0xFFFFFF);
		
		txtName.x = biteIcons.x + biteIcons.width + 6;
		txtName.y = biteIcons.y - 7;
		
		txtData.x = txtName.x;
		txtData.y = txtName.y + txtName.height + 4;
		
		GUIFactory.fillSprite(this, [background, biteIcons, txtName, txtData]);
	}
	
	public function update(index:Int, data:Player, ct:ColorTransform):Void {
		if (data.alive != alive) {
			tintTo(data.alive ? ct : DEAD_CT);
			alive = data.alive;
		}
		
		if (biteIcon != null) biteIcon.visible = false;
		biteIcon = biteIcons.getChildAt(data.biteSize - 1);
		biteIcon.visible = true;
		
		txtName.text = data.name;
		txtData.text = "BITES: " + Std.string(data.bites) + "   SWAPS: " + Std.string(data.swaps);
		shiftTo(height * index);
	}
	
	private function tintTo(ct:ColorTransform):Void {
		if (tintJob != null) tintJob.complete();
		var tween:Dynamic = {};
		tween.redMultiplier = ct.redMultiplier;
		tween.greenMultiplier = ct.greenMultiplier;
		tween.blueMultiplier = ct.blueMultiplier;
		tintJob = KTween.to(tint, 0.5, tween, Quad.easeInOut);
		tintJob.onChange = updateTint;
	}
	
	private function updateTint():Void {
		transform.colorTransform = tint;
	}
	
	private function shiftTo(newY:Float):Void {
		// tween to this new position
		if (shiftJob != null) shiftJob.close();
		shiftJob = KTween.to(this, 0.2, {y:newY}, Quad.easeInOut);
	}
}