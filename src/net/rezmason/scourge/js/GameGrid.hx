package net.rezmason.scourge.js;

import easeljs.Bitmap;
import easeljs.Container;
import easeljs.Shape;

import net.kawa.tween.KTween;
import net.kawa.tween.KTJob;
import net.kawa.tween.easing.Linear;

class GameGrid extends Container {
	/*
	private static var BITE_GLOW:GlowFilter = new GlowFilter(0xFFFFFF, 1, 9, 9, 20, 1, true);
	private static var ALPHA_BLUR:BlurFilter = new BlurFilter(10, 10, 3);
	private static var ORIGIN:Point = new Point();
	
	private static var SLIME_MAKER:GlowFilter = new GlowFilter(0x0, 1, 14, 14, 2.5, 1, true);
	private static var BLUR_FILTER:BlurFilter = new BlurFilter(6, 6, 2);
	private static var GRID_BLUR:BlurFilter = new BlurFilter(4, 4, 1);
	
	private static var COMPLETE_EVENT:Event = new Event(Event.COMPLETE);
	
	*/
	public var firstBiteCheck:Int->Int->Array<Int>;
	public var endBiteCheck:Int->Int->Void;
	public var space:Shape;
	
	private var background:Shape;
	//private var pattern:Grid;
	//private var blurredPatternData:BitmapData;
	private var blurredPattern:Shape;
	private var clouds:Shape;
	private var bodies:Container;
	private var heads:Container;
	private var teeth:Container;
	private var toothPool:Array<Container>;
	//private var fadeSourceBitmap:BitmapData;
	//private var fadeAlphaBitmap:BitmapData;
	//private var fadeBitmap:BitmapData;
	private var fader:Shape;
	private var biteTooth:BiteTooth;
	private var biteToothJob:KTJob;
	
	private var playerBodies:Array<Shape>;
	private var playerHeads:Array<Shape>;
	//private var playerBitmaps:Array<BitmapData>;
	
	private var fadeSequence:Array<Int>;
	private var fadeJob:KTJob;
	private var fadeCount:Float;
	private var fadeDuration:Float;
	private var fadeMult:Float;
	private var gridTeethJob:KTJob;
	private var draggingBite:Bool;
	private var biteLimits:Array<Int>;
	
	public function new():Void {
		
		super();
		
		var bmpSize:Int = Common.BOARD_SIZE * Layout.UNIT_SIZE;
		
		background = GUIFactory.drawSolidRect(new Shape(), 0x444444, 1, 0, 0, bmpSize + 20, bmpSize + 20, 6);
		GUIFactory.drawSolidRect(background, 0x101010, 1, 4, 4, bmpSize + 12, bmpSize + 12, 4);
		GUIFactory.fillContainer(this, [background]);
	}
}