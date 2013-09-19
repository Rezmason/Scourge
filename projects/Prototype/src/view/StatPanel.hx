package view;

import flash.display.Shape;
import flash.display.Sprite;
import flash.geom.ColorTransform;

class StatPanel extends Sprite {

	private var background:Shape;
	private var container:Sprite;
	private var playerStatPool:Array<PlayerStat>;

	public function new():Void {
		super();

		playerStatPool = [];

		background = GUIFactory.drawSolidRect(new Shape(), 0x606060, 1, 0, 0, Layout.WELL_WIDTH, Layout.STAT_PANEL_HEIGHT, Layout.BAR_CORNER_RADIUS);
		container = new Sprite();
		container.mask = GUIFactory.drawSolidRect(new Shape(), 0x0, 1, 0, 0, Layout.WELL_WIDTH, Layout.STAT_PANEL_HEIGHT, Layout.BAR_CORNER_RADIUS);
		GUIFactory.fillSprite(this, [background, container, container.mask]);

		for (ike in 0...Common.MAX_PLAYERS) playerStatPool.push(new PlayerStat(ike + 1, Layout.STAT_PANEL_HEIGHT / Common.MAX_PLAYERS));
	}

	public function update(playerData:Array<Player>, cts:Array<ColorTransform>):Void {
		while (container.numChildren > 0) container.removeChildAt(0);
		for (ike in 0...playerData.length) {
			var stat:PlayerStat = playerStatPool[playerData[ike].order - 1];
			container.addChildAt(stat, 0);
			stat.update(ike, playerData[ike], cts[playerData[ike].color]);
		}
	}

	public function tint(ct:ColorTransform):Void {
		background.transform.colorTransform = ct;
	}
}
