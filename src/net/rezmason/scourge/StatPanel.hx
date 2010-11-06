package net.rezmason.scourge;

import flash.display.BitmapData;
import flash.display.Shape;
import flash.display.Sprite;
import flash.geom.ColorTransform;

import net.kawa.tween.KTJob;
import net.kawa.tween.KTween;
import net.kawa.tween.easing.Quad;

import flash.Lib;

class StatPanel extends Sprite {
	
	private var background:Shape;
	private var updateTween:KTJob;
	private var snapshotBitmap:BitmapData;
	private var snapshot:Shape;
	
	public function new(hgt:Float):Void {
		super();
		background = GUIFactory.drawSolidRect(new Shape(), 0x222222, 1, 0, 0, 210, hgt, 40);
		snapshotBitmap = new BitmapData(210, Std.int(hgt), true, 0x0);
		snapshot = GUIFactory.makeBitmapShape(snapshotBitmap, 1, true);
		background.visible = false;
		GUIFactory.fillSprite(this, [background, snapshot]);
	}
	
	public function update(player:Player, ct:ColorTransform):Void {
		if (updateTween != null) updateTween.complete();
		snapshot.visible = false;
		snapshotBitmap.fillRect(snapshotBitmap.rect, 0x0);
		snapshotBitmap.draw(this);
		snapshot.visible = true;
		snapshot.alpha = 1;
		background.visible = true;
		
		background.transform.colorTransform = ct;
		
		updateTween = KTween.to(snapshot, 0.3, {alpha:0, visible:true}, Quad.easeOut);
	}
}