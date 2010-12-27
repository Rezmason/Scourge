package net.rezmason.scourge.flash;

import flash.display.BitmapData;
import flash.display.BitmapDataChannel;
import flash.display.BlendMode;
import flash.display.Shape;
import flash.display.Sprite;
import flash.events.Event;
import flash.filters.BlurFilter;
import flash.filters.GlowFilter;
import flash.geom.ColorTransform;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;

import net.rezmason.scourge.Common;
import net.rezmason.scourge.Layout;
import net.rezmason.flash.display.Grid;

import net.kawa.tween.KTween;
import net.kawa.tween.KTJob;
import net.kawa.tween.easing.Linear;

import flash.Lib;

class GameGrid extends Sprite {
	
	private static var BITE_GLOW:GlowFilter = new GlowFilter(0xFFFFFF, 1, 9, 9, 20, 1, true);
	private static var ALPHA_BLUR:BlurFilter = new BlurFilter(10, 10, 3);
	private static var DUMB_POINT:Point = new Point();
	
	private static var COMPLETE_EVENT:Event = new Event(Event.COMPLETE);
	
	public var background:Shape;
	public var pattern:Grid;
	public var blurredPatternData:BitmapData;
	public var blurredPattern:Shape;
	public var biteRegion:Shape;
	public var clouds:Shape;
	public var bodies:Sprite;
	public var heads:Sprite;
	public var teeth:Sprite;
	private var fadeSourceBitmap:BitmapData;
	private var fadeAlphaBitmap:BitmapData;
	private var fadeBitmap:BitmapData;
	private var fader:Shape;
	public var biteTooth:BiteTooth;
	
	private var fadeSequence:Array<Int>;
	private var fadeJob:KTJob;
	private var fadeCount:Float;
	private var fadeDuration:Float;
	private var fadeMult:Float;
	
	public function new(headShapes:Array<Shape>, bodyShapes:Array<Shape>):Void {
		
		super();
		
		fadeMult = 10;
		
		var bmpSize:Int = Common.BOARD_SIZE * Layout.UNIT_SIZE;
		
		background = GUIFactory.drawSolidRect(new Shape(), 0x444444, 1, 0, 0, bmpSize + 20, bmpSize + 20, 6);
		GUIFactory.drawSolidRect(background, 0x101010, 1, 4, 4, bmpSize + 12, bmpSize + 12, 4);
		biteRegion = new Shape();
		bodies = new Sprite();
		bodies.transform.colorTransform = new ColorTransform(0.6, 0.6, 0.6, 3);
		bodies.blendMode = BlendMode.ADD;
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
		fadeSourceBitmap = new BitmapData(bmpSize, bmpSize, true, 0x0);
		fadeBitmap = fadeSourceBitmap.clone();
		fader = GUIFactory.makeBitmapShape(fadeBitmap, 1, true);
		fadeAlphaBitmap = fadeSourceBitmap.clone();
		fader.x = fader.y = Layout.BOARD_BORDER;
		biteTooth = new BiteTooth();
		biteTooth.x = biteTooth.y = bmpSize / 2;
		
		GUIFactory.fillSprite(heads, headShapes);
		GUIFactory.fillSprite(bodies, bodyShapes);
		
		GUIFactory.fillSprite(this, [
			background, 
			pattern, 
			blurredPattern, 
			bodies,
			clouds, 
			fader,
			heads, 
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
	
	public function fadeByFreshness(arr:Array<Int>, max:Int):Void {
		
		if (fadeJob != null) fadeJob.complete();
		
		// Sequence the changed indices
		
		fadeSequence = [];
		
		var fadeSequences:Array<Array<Int>> = [];
		for (ike in 0...Common.BOARD_NUM_CELLS) {
			var freshness:Int = arr[ike] - 1;
			if (freshness >= 0) {
				var seq:Array<Int> = fadeSequences[freshness];
				if (seq == null) seq = fadeSequences[freshness] = [];
				seq.push(ike);
			}
		}
		
		for (ike in 0...fadeSequences.length) {
			var seq:Array<Int> = fadeSequences[ike];
			seq.sort(randSort);
			fadeSequence = fadeSequence.concat(seq);
		}
		
		fadeDuration = fadeSequence.length * 0.05;
		
		fadeCount = 0;
		fadeJob = KTween.to(this, fadeDuration, {fadeCount:fadeSequence.length + fadeMult / 2}, Linear.easeOut, fadeComplete);
		fadeJob.onChange = fadeUpdate;
		fadeUpdate();
		fader.visible = true;
	}
	
	private function randSort(one:Int, two:Int):Int {
		return Math.random() > 0.5 ? 1 : -1;
	}
	
	private function fadeUpdate():Void {
		
		fadeAlphaBitmap.fillRect(fadeAlphaBitmap.rect, 0xFFFFFFFF);
		
		// draw the patches to fadeAlphaBitmap
		
		var rect:Rectangle = new Rectangle();
		var totalRect:Rectangle = null;
		var w:Int = Common.BOARD_SIZE;
		var margin:Float = Layout.UNIT_SIZE * 0.5;
		rect.width = rect.height = Layout.UNIT_SIZE + 2 * margin;
		var ike:Int = Std.int(fadeCount);
		while (ike >= 0) {
			var val:Float = (fadeMult - Math.min(fadeMult, fadeCount - ike)) / fadeMult;
			var alpha:Int = Std.int(0xFF * val * val);
			var index:Int = fadeSequence[ike];
			var tx:Int = (index % w);
			var ty:Int = Std.int((index - tx) / w);
			rect.x = tx * Layout.UNIT_SIZE - margin;
			rect.y = ty * Layout.UNIT_SIZE - margin;
			if (totalRect == null) {
				totalRect = rect.clone();
			} else {
				totalRect = totalRect.union(rect);
			}
			fadeAlphaBitmap.fillRect(rect, alpha | 0xFFFFFF00);
			ike--;
		}
		
		fadeAlphaBitmap.applyFilter(fadeAlphaBitmap, totalRect, totalRect.topLeft, ALPHA_BLUR);
		fadeBitmap.copyPixels(fadeSourceBitmap, fadeSourceBitmap.rect, DUMB_POINT);
		fadeBitmap.copyChannel(fadeAlphaBitmap, fadeAlphaBitmap.rect, DUMB_POINT, BitmapDataChannel.BLUE, BitmapDataChannel.ALPHA);
	}
	
	private function fadeComplete():Void {
		fader.visible = false;
		updateFadeSourceBitmap();
		dispatchEvent(COMPLETE_EVENT);
	}
	
	public function updateFadeSourceBitmap():Void {
		var biteToothWasVisible:Bool = biteTooth.visible;
		heads.visible = teeth.visible = biteTooth.visible = fader.visible = false;
		var mat:Matrix = new Matrix(1, 0, 0, 1, -Layout.BOARD_BORDER, -Layout.BOARD_BORDER);
		fadeSourceBitmap.fillRect(fadeSourceBitmap.rect, 0x0);
		fadeSourceBitmap.draw(this, mat);
		teeth.visible = heads.visible = true;
		biteTooth.visible = biteToothWasVisible;
	}
}