package net.rezmason.scourge.flash;

import flash.display.BitmapData;
import flash.display.Shape;
import flash.display.Sprite;
import flash.geom.ColorTransform;
import flash.text.TextField;

import net.rezmason.scourge.Player;
import net.rezmason.scourge.Common;

import flash.Lib;

class StatPanel extends Sprite {
	
	private var background:Shape;
	private var container:Sprite;
	private var playerStatPool:Array<PlayerStat>;
	
	public function new(hgt:Float):Void {
		super();
		
		playerStatPool = [];
		
		background = GUIFactory.drawSolidRect(new Shape(), 0x222222, 1, 0, 0, 210, hgt, 40);
		container = new Sprite();
		container.mask = GUIFactory.drawSolidRect(new Shape(), 0x0, 1, 0, 0, 210, hgt, 40);
		GUIFactory.fillSprite(this, [background, container, container.mask]);
		
		for (ike in 0...Common.MAX_PLAYERS) playerStatPool.push(new PlayerStat(ike + 1, hgt / Common.MAX_PLAYERS));
	}
	
	public function update(playerData:Array<Player>, cts:Array<ColorTransform>):Void {
		while (container.numChildren > 0) container.removeChildAt(0);
		for (ike in 0...playerData.length) {
			var stat:PlayerStat = playerStatPool[playerData[ike].id - 1];
			container.addChildAt(stat, 0);
			stat.update(ike, playerData[ike], cts[stat.id - 1]);
		}
	}
	
	public function tint(ct:ColorTransform):Void {
		background.transform.colorTransform = ct;
	}
}