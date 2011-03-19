package net.rezmason.scourge.js;

import easeljs.Container;
import easeljs.Graphics;
import easeljs.Shape;

import net.rezmason.scourge.Common;
import net.rezmason.scourge.Layout;
import net.rezmason.scourge.Player;

class StatPanel extends Container {
	
	private var background:Shape;
	private var container:Container;
	private var playerStatPool:Array<PlayerStat>;
	
	public function new(hgt:Float):Void {
		super();
		
		playerStatPool = [];
		
		background = GUIFactory.drawSolidRect(new Shape(), 0x333333, 1, 0, 0, 210, hgt, Layout.BAR_CORNER_RADIUS);
		container = new Container();
		//container.mask = GUIFactory.drawSolidRect(new Shape(), 0x0, 1, 0, 0, 210, hgt, Layout.BAR_CORNER_RADIUS);
		GUIFactory.fillContainer(this, [background, container/*, container.mask*/]);
		
		for (ike in 0...Common.MAX_PLAYERS) playerStatPool.push(new PlayerStat(ike + 1, hgt / Common.MAX_PLAYERS));
	}
	/*
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
	*/
}