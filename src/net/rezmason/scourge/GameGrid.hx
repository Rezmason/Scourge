package net.rezmason.scourge;

import flash.display.BitmapData;
import flash.display.BlendMode;
import flash.display.Shape;
import flash.display.Sprite;
import flash.filters.GlowFilter;
import flash.geom.ColorTransform;
import flash.geom.Rectangle;

import net.rezmason.display.Grid;

class GameGrid extends Sprite {
	
	private static var BITE_GLOW:GlowFilter = new GlowFilter(0xFFFFFF, 1, 9, 9, 20, 1, true);
	
	public var background:Shape;
	public var pattern:Grid;
	public var blurredPatternData:BitmapData;
	public var blurredPattern:Shape;
	public var biteRegion:Shape;
	public var clouds:Shape;
	public var teams:Sprite;
	public var heads:Sprite;
	public var teeth:Sprite;
	public var faderBitmap:BitmapData;
	public var fader:Shape;
	public var biteTooth:BiteTooth;
	
	public function new():Void {
		
		super();
		
		var bmpSize:Int = Common.BOARD_SIZE * Layout.UNIT_SIZE;
		
		background = GUIFactory.drawSolidRect(new Shape(), 0x444444, 1, 0, 0, bmpSize + 20, bmpSize + 20, 6);
		GUIFactory.drawSolidRect(background, 0x101010, 1, 4, 4, bmpSize + 12, bmpSize + 12, 4);
		biteRegion = new Shape();
		teams = new Sprite();
		teams.transform.colorTransform = new ColorTransform(0.6, 0.6, 0.6, 3);
		teams.blendMode = BlendMode.ADD;
		heads = new Sprite();
		heads.x = heads.y = Layout.BOARD_BORDER;
		heads.mouseEnabled = heads.mouseChildren = false;
		pattern = new Grid(Layout.UNIT_SIZE * 2, bmpSize, bmpSize, 0xFF111111, 0xFF222222);
		pattern.x = pattern.y = Layout.BOARD_BORDER;
		blurredPatternData = new BitmapData(bmpSize, bmpSize, true, 0x0);
		blurredPattern = GUIFactory.makeBitmapShape(blurredPatternData, 1, true);
		blurredPattern.x = blurredPattern.y = pattern.x;
		var cloudCover:BitmapData = new BitmapData(bmpSize, bmpSize, false, 0xFF000000);
		cloudCover.perlinNoise(30, 30, 3, Std.int(Math.random() * 0xFF), false, true, 7, true);
		var cloudAmount:Float = 0.7;
		cloudCover.colorTransform(cloudCover.rect, new ColorTransform(cloudAmount, cloudAmount, cloudAmount));
		clouds = GUIFactory.makeBitmapShape(cloudCover, 1, true);
		clouds.x = clouds.y = Layout.BOARD_BORDER;
		clouds.blendMode = BlendMode.OVERLAY;
		teeth = new Sprite();
		teeth.visible = false;
		teeth.mouseEnabled = teeth.mouseChildren = false;
		teeth.alpha = 0;
		teeth.filters = [BITE_GLOW];
		teeth.x = teeth.y = Layout.BOARD_BORDER;
		faderBitmap = new BitmapData(bmpSize, bmpSize, true, 0x0);
		fader = GUIFactory.makeBitmapShape(faderBitmap, 1, true);
		fader.blendMode = BlendMode.LAYER;
		fader.x = fader.y = Layout.BOARD_BORDER;
		biteTooth = new BiteTooth();
		
		GUIFactory.fillSprite(this, [
			background, 
			pattern, 
			blurredPattern, 
			teams, 
			heads, 
			clouds, 
			fader, 
			teeth, 
			biteTooth 
		]);
		
		cacheAsBitmap = true;
		tabEnabled = !(buttonMode = useHandCursor = true);
		
	}
	
	public function tint(color:Int):Void {
		BITE_GLOW.color = color;
		teeth.filters = [BITE_GLOW];
	}
	
	public function getHitBox():Rectangle {
		return pattern.getBounds(pattern);
	}
}