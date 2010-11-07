package net.rezmason.scourge;

import flash.display.BitmapData;
import flash.display.Shape;
import flash.display.Sprite;
import flash.filters.GlowFilter;
import flash.geom.ColorTransform;
import flash.text.TextField;

import net.kawa.tween.KTJob;
import net.kawa.tween.KTween;
import net.kawa.tween.easing.Quad;

import flash.Lib;

class StatPanel extends Sprite {
	
	private var background:Shape;
	private var updateTween:KTJob;
	private var snapshotBitmap:BitmapData;
	private var snapshot:Shape;
	private var biteIcon1:Sprite;
	private var biteIcon2:Sprite;
	private var biteIcon3:Sprite;
	private var biteIcons:Sprite;
	private var contents:Sprite;
	private var txtName:TextField;
	private var txtData:TextField;
	private var txtCaption:TextField;
	private var sizeChart:Sprite;
	
	public function new(hgt:Float):Void {
		super();
		
		background = GUIFactory.drawSolidRect(new Shape(), 0x222222, 1, 0, 0, 210, hgt, 40);
		snapshotBitmap = new BitmapData(210, Std.int(hgt), true, 0x0);
		snapshot = GUIFactory.makeBitmapShape(snapshotBitmap, 1, true);
		background.visible = false;
		biteIcon1 = new ScourgeLib_BiteIcon1();
		biteIcon2 = new ScourgeLib_BiteIcon2();
		biteIcon3 = new ScourgeLib_BiteIcon3();
		biteIcons = GUIFactory.fillSprite(new Sprite(), [biteIcon1, biteIcon2, biteIcon3]);
		biteIcons.transform.colorTransform = new ColorTransform(1, 1, 1, 1, 0xFF, 0xFF, 0xFF);
		biteIcons.width = biteIcons.height = 50;
		biteIcons.visible = false;
		txtName = GUIFactory.makeTextBox(210 - 3 * Layout.BAR_MARGIN - biteIcons.width, 40, GUIFactory.MISO, 40, 0xFFFFFF, true);
		txtCaption = GUIFactory.makeTextBox(210 - 2 * Layout.BAR_MARGIN, 100, GUIFactory.MISO, 26, 0xFFFFFF, false, true);
		txtData = GUIFactory.makeTextBox(210 - 2 * Layout.BAR_MARGIN, 100, GUIFactory.MISO, 26, 0xFFFFFF, true, true);
		
		contents = GUIFactory.fillSprite(new Sprite(), [txtName, biteIcons, txtCaption, txtData]);
		GUIFactory.fillSprite(this, [background, contents, snapshot]);
		
		biteIcons.x = biteIcons.y = Layout.BAR_MARGIN;
		txtName.x = biteIcons.x + biteIcons.width + Layout.BAR_MARGIN;
		txtName.y = Layout.BAR_MARGIN;
		txtData.x = biteIcons.x;
		txtData.y = biteIcons.y + biteIcons.height + Layout.BAR_MARGIN;
		txtCaption.x = biteIcons.x;
		txtCaption.y = biteIcons.y + biteIcons.height + Layout.BAR_MARGIN;
		txtCaption.text = "SIZE\nBITES\nSWAPS";
		txtCaption.visible = false;
		
	}
	
	public function update(player:Player, ct:ColorTransform):Void {
		if (player == null) return;
		if (updateTween != null) updateTween.complete();
		snapshot.visible = false;
		snapshotBitmap.fillRect(snapshotBitmap.rect, 0x0);
		snapshotBitmap.draw(this);
		snapshot.visible = true;
		snapshot.alpha = 1;
		background.visible = true;
		biteIcons.visible = true;
		biteIcon1.visible = player.biteSize == 1;
		biteIcon2.visible = player.biteSize == 2;
		biteIcon3.visible = player.biteSize == 3;
		txtName.text = player.name;
		txtCaption.visible = true;
		txtData.text = [player.size, player.bites, player.swaps].join("\n");
		background.transform.colorTransform = ct;
		contents.transform.colorTransform = ct;
		
		updateTween = KTween.to(snapshot, 0.3, {alpha:0, visible:true}, Quad.easeOut);
	}
}