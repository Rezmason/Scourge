package net.rezmason.scourge.flash;

import flash.display.BitmapData;
import flash.display.BitmapDataChannel;
import flash.display.BlendMode;
import flash.display.Shape;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.filters.BlurFilter;
import flash.filters.GlowFilter;
import flash.geom.ColorTransform;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;

import net.rezmason.scourge.Common;
import net.rezmason.scourge.Layout;
import net.rezmason.scourge.Player;
import net.rezmason.flash.display.Grid;

import net.kawa.tween.KTween;
import net.kawa.tween.KTJob;
import net.kawa.tween.easing.Linear;

class GameGrid extends Sprite {
	
	private static var BITE_GLOW:GlowFilter = new GlowFilter(0xFFFFFF, 1, 9, 9, 20, 1, true);
	private static var ALPHA_BLUR:BlurFilter = new BlurFilter(10, 10, 3);
	private static var ORIGIN:Point = new Point();
	
	private static var SLIME_MAKER:GlowFilter = new GlowFilter(0x0, 1, 14, 14, 2.5, 1, true);
	private static var BLUR_FILTER:BlurFilter = new BlurFilter(6, 6, 2);
	private static var GRID_BLUR:BlurFilter = new BlurFilter(4, 4, 1);
	
	private static var COMPLETE_EVENT:Event = new Event(Event.COMPLETE);
	
	public var firstBiteCheck:Int->Int->Array<Int>;
	public var endBiteCheck:Int->Int->Void;
	public var space:Shape;
	
	private var background:Shape;
	private var pattern:Grid;
	private var blurredPatternData:BitmapData;
	private var blurredPattern:Shape;
	private var clouds:Shape;
	private var bodies:Sprite;
	private var heads:Sprite;
	private var teeth:Sprite;
	private var toothPool:Array<Sprite>;
	private var fadeSourceBitmap:BitmapData;
	private var fadeAlphaBitmap:BitmapData;
	private var fadeBitmap:BitmapData;
	private var fader:Shape;
	private var biteTooth:BiteTooth;
	private var biteToothJob:KTJob;
	
	private var playerBodies:Array<Shape>;
	private var playerHeads:Array<Shape>;
	private var playerBitmaps:Array<BitmapData>;
	
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
		
		fadeMult = 10;
		draggingBite = false;
		
		playerHeads = [];
		playerBodies = [];
		playerBitmaps = [];
		
		var bmpSize:Int = Common.BOARD_SIZE * Layout.UNIT_SIZE;
		
		background = GUIFactory.drawSolidRect(new Shape(), 0x444444, 1, 0, 0, bmpSize + 20, bmpSize + 20, 6);
		GUIFactory.drawSolidRect(background, 0x101010, 1, 4, 4, bmpSize + 12, bmpSize + 12, 4);
		bodies = new Sprite();
		bodies.transform.colorTransform = new ColorTransform(0.6, 0.6, 0.6, 3);
		bodies.blendMode = BlendMode.ADD;
		heads = new Sprite();
		heads.x = heads.y = Layout.BOARD_BORDER;
		heads.mouseEnabled = heads.mouseChildren = false;
		space = new Shape();
		space.x = space.y = Layout.BOARD_BORDER;
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
		toothPool = [];
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
		
		GUIFactory.fillSprite(this, [
			background, 
			space,
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
		
		teeth.addEventListener(MouseEvent.MOUSE_DOWN, firstBite);
		
		teeth.addEventListener(MouseEvent.MOUSE_OVER, updateBiteTooth);
		teeth.addEventListener(MouseEvent.ROLL_OUT, updateBiteTooth);
		
		addEventListener(Event.ADDED_TO_STAGE, connectToStage);
	}
	
	private function connectToStage(event:Event):Void {
		removeEventListener(Event.ADDED_TO_STAGE, connectToStage);
		stage.addEventListener(MouseEvent.MOUSE_UP, endBite);
		stage.addEventListener(MouseEvent.MOUSE_MOVE, mouseHandler);
	}
	
	private function mouseHandler(event:Event):Void {
		if (draggingBite) dragBite();
	}
	
	public function tintTeeth(color:Int):Void {
		BITE_GLOW.color = color;
		teeth.filters = [BITE_GLOW];
	}
	
	public function getHitBox():Rectangle { return pattern.getBounds(pattern); }
	
	public function fadeByFreshness(arr:Array<Int>, max:Int):Void {
		
		if (fadeJob != null) fadeJob.complete();
		
		// Sequence the changed indices
		
		var fadeSequences:Array<Array<Int>> = [];
		for (ike in 0...Common.BOARD_NUM_CELLS) {
			var freshness:Int = arr[ike] - 1;
			if (freshness >= 0) {
				var seq:Array<Int> = fadeSequences[freshness];
				if (seq == null) seq = fadeSequences[freshness] = [];
				seq.push(ike);
			}
		}
		
		fadeSequence = [];
		
		for (ike in 0...fadeSequences.length) {
			var seq:Array<Int> = fadeSequences[ike];
			seq.sort(randSort);
			fadeSequence = fadeSequence.concat(seq);
		}
		
		fadeDuration = Math.log(fadeSequence.length) * 0.2;
		
		fadeCount = 0;
		fadeJob = KTween.to(this, fadeDuration, {fadeCount:fadeSequence.length + fadeMult / 2}, Linear.easeOut, fadeComplete);
		fadeJob.onChange = fadeUpdate;
		fadeUpdate();
		fader.visible = true;
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
	
	public function makePlayerHeadAndBody(ct:ColorTransform):Void {
		var bmpSize:Int = Common.BOARD_SIZE * Layout.UNIT_SIZE + 2 * Layout.BOARD_BORDER;
		
		var bmp:BitmapData = new BitmapData(bmpSize, bmpSize, true, 0x0);
		playerBitmaps.push(bmp);
		
		var body:Shape = GUIFactory.makeBitmapShape(bmp, 1, true, ct);
		var head:Shape = GUIFactory.makeHead(Layout.UNIT_SIZE, ct);
		
		playerBodies.push(body);
		bodies.addChild(body);
		playerHeads.push(head);
		heads.addChild(head);
	}
	
	public function updateBodies(colorGrid:Array<Int>):Void {
		var len:Int = Common.BOARD_NUM_CELLS;
		var rect:Rectangle = new Rectangle(0, 0, Layout.UNIT_SIZE, Layout.UNIT_SIZE);
		rect.inflate(1, 1);
		var rx:Int, ry:Int;
		
		preparePlayerBitmaps();
		
		for (ike in 0...len) {
			if (colorGrid[ike] > 0) {
				rx = ike % Common.BOARD_SIZE;
				ry = Std.int((ike - rx) / Common.BOARD_SIZE);
				rect.x = rx * Layout.UNIT_SIZE + Layout.BOARD_BORDER;
				rect.y = ry * Layout.UNIT_SIZE + Layout.BOARD_BORDER;
				rect.x -= 1;
				rect.y -= 1;
				playerBitmaps[colorGrid[ike] - 1].fillRect(rect, 0xFFFFFFFF);
			}
		}
		
		finishPlayerBitmaps();
	}
	
	public function updateHeads(players:Array<Player>):Void {
		for (ike in 0...players.length) {
			var head:Shape = playerHeads[ike];
			if (head.alpha == 1 && !players[ike].alive) {
				KTween.to(head, Layout.QUICK * 5, {scaleX:1, scaleY:1, alpha:0, visible:false}, Linear.easeOut);
			} else {
				head.visible = true;
			}
		}
	}
	
	public function initHeads(numPlayers:Int):Void {
		var headPositions:Array<Int> = Common.HEAD_POSITIONS[numPlayers - 1];
		
		for (ike in 0...Common.MAX_PLAYERS) {
			var head:Shape = playerHeads[ike];
			if (ike * 2 < headPositions.length) {
				head.visible = true;
				head.alpha = 1;
				head.x = (headPositions[ike * 2    ] + 0.5) * Layout.UNIT_SIZE;
				head.y = (headPositions[ike * 2 + 1] + 0.5) * Layout.UNIT_SIZE;
			} else {
				head.visible = false;
			}
		}
	}
	
	public function showTeeth():Void {
		if (gridTeethJob != null) gridTeethJob.close();
		if (biteToothJob != null) biteToothJob.close();
		teeth.visible = true;
		teeth.mouseEnabled = teeth.mouseChildren = true;
		gridTeethJob = KTween.to(teeth, Layout.QUICK * 2, {alpha:1}, Layout.POUNCE);
	}
	
	public function hideTeeth(playerIndex:Int):Void {
		if (gridTeethJob != null) gridTeethJob.close();
		if (biteToothJob != null) biteToothJob.close();
		draggingBite = false;
		teeth.mouseEnabled = teeth.mouseChildren = false;
		gridTeethJob = KTween.to(teeth, Layout.QUICK * 2, {alpha:0, visible:false}, Layout.POUNCE);
		biteToothJob = KTween.to(biteTooth, Layout.QUICK, {scaleX:0.5, scaleY:0.5, alpha:0, visible:false}, Layout.POUNCE, biteTooth.reset);
		playerHeads[playerIndex].visible = true;
	}
	
	public function updateTeeth(br:Array<Bool>, index:Int, headX:Int, headY:Int, ct:ColorTransform):Void {
		
		if (br == null) br = [];
		
		var head:Shape = playerHeads[index];
		var bx:Int, by:Int;
		var totalTeeth:Int = teeth.numChildren;
		var tooth:Sprite;
		var toothItr:Int = 0;
		
		var arr:Array<Int> = [];
		for (ike in 0...br.length) {
			if (!br[ike]) continue;
			by = Std.int(ike / Common.BOARD_SIZE);
			bx = ike - by * Common.BOARD_SIZE;
			if (bx == headX && by == headY) head.visible = false;
			if (toothItr > toothPool.length - 1) {
				tooth = GUIFactory.makeTooth(Layout.UNIT_SIZE * 1.25);
				toothPool.push(tooth);
			} else {
				tooth = toothPool[toothItr];
				tooth.visible = true;
			}
			
			tooth.transform.colorTransform = ct;
			tooth.x = (bx + 0.5) * Layout.UNIT_SIZE;
			tooth.y = (by + 0.5) * Layout.UNIT_SIZE;
			teeth.addChild(tooth);
			
			toothItr++;
		}
		for (ike in toothItr...toothPool.length) toothPool[ike].visible = false;
	}
	
	public function isDraggingBite():Bool { return draggingBite; }
	
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
		fadeBitmap.copyPixels(fadeSourceBitmap, fadeSourceBitmap.rect, ORIGIN);
		fadeBitmap.copyChannel(fadeAlphaBitmap, fadeAlphaBitmap.rect, ORIGIN, BitmapDataChannel.BLUE, BitmapDataChannel.ALPHA);
	}
	
	private function fadeComplete():Void {
		fader.visible = false;
		updateFadeSourceBitmap();
		dispatchEvent(COMPLETE_EVENT);
	}
	
	private function preparePlayerBitmaps():Void {
		for (ike in 0...Common.MAX_PLAYERS) playerBitmaps[ike].fillRect(playerBitmaps[ike].rect, 0x0);
	}
	
	private function finishPlayerBitmaps():Void {
		var bmp:BitmapData;
		var bmpSize:Int = Common.BOARD_SIZE * Layout.UNIT_SIZE + 2 * Layout.BOARD_BORDER;
		var bmp2:BitmapData = new BitmapData(bmpSize, bmpSize, true, 0x0);
		
		for (ike in 0...Common.MAX_PLAYERS) {
			bmp = playerBitmaps[ike];
			
			bmp.applyFilter(bmp, bmp.rect, ORIGIN, SLIME_MAKER);
			bmp2.fillRect(bmp.rect, 0x0);
			bmp2.draw(bmp);
			
			bmp.fillRect(bmp.rect, 0xFFFFFFFF);
			bmp.copyChannel(bmp2, bmp.rect, ORIGIN, BitmapDataChannel.RED, BitmapDataChannel.ALPHA);
			bmp.applyFilter(bmp, bmp.rect, ORIGIN, BLUR_FILTER);
		}
		
		bmp2.fillRect(bmp2.rect, 0xFF000000);
		var mat:Matrix = new Matrix();
		mat.tx = -pattern.x;
		mat.ty = -pattern.y;
		for (ike in 0...Common.MAX_PLAYERS) bmp2.draw(playerBitmaps[ike], mat, null, BlendMode.ADD);
		blurredPatternData.draw(pattern);
		blurredPatternData.applyFilter(blurredPatternData, blurredPatternData.rect, ORIGIN, GRID_BLUR);
		//blurredPatternData.fillRect(blurredPatternData.rect, 0xFFFFFFFF);
		blurredPatternData.copyChannel(bmp2, bmp2.rect, ORIGIN, BitmapDataChannel.RED, BitmapDataChannel.ALPHA);
	}
	
	private function fillBoardRandomly(?event:Event):Void {
		var bmp:BitmapData;
		var whatev:Array<Array<Null<Bool>>> = [];
		var rect:Rectangle = new Rectangle();
		
		preparePlayerBitmaps();
		
		for (ike in 0...Common.MAX_PLAYERS) {
			bmp = playerBitmaps[ike];
			
			for (jen in 0...80) {
				var rx:Int = 0;
				var ry:Int = 0;
				while (true) {
					rx = Std.int(Math.random() * Common.BOARD_SIZE) * Layout.UNIT_SIZE;
					ry = Std.int(Math.random() * Common.BOARD_SIZE) * Layout.UNIT_SIZE;
					if (whatev[ry] == null) {
						whatev[ry] = [];
					}
					if (whatev[ry][rx] == null) {
						whatev[ry][rx] = true;
						break;
					}
				}	
				rect.x = rx + Layout.BOARD_BORDER;
				rect.y = ry + Layout.BOARD_BORDER;
				rect.width = rect.height = Layout.UNIT_SIZE;
				bmp.fillRect(rect, 0xFFFFFFFF);
			}
		}
		
		finishPlayerBitmaps();
	}
	
	private function firstBite(?event:Event):Void {
		if (draggingBite) return;
		draggingBite = true;
		var bX:Int = Std.int(teeth.mouseX / Layout.UNIT_SIZE);
		var bY:Int = Std.int(teeth.mouseY / Layout.UNIT_SIZE);
		biteLimits = firstBiteCheck(bX, bY);
	}
	
	private function dragBite():Void {
		
		var dX:Int = Std.int(biteTooth.mouseX / Layout.UNIT_SIZE);
		var dY:Int = Std.int(biteTooth.mouseY / Layout.UNIT_SIZE);
		var horiz:Bool = false;
		
		if (biteTooth.endX != 0) {
			horiz = true;
		} else if (biteTooth.endY != 0) {
			horiz = false;
		} else if (dY == 0) {
			horiz = true;
		} else if (dX == 0) {
			horiz = false;
		} else {
			horiz = Math.abs(dX) > Math.abs(dY);
		}
		
		var min:Int = horiz ? biteLimits[3] : biteLimits[0];
		var max:Int = horiz ? biteLimits[1] : biteLimits[2];
		var val:Int = horiz ? dX : dY;
		
		biteTooth.stretchTo(Std.int(Math.max(min, Math.min(val, max))), horiz);
	}
	
	private function endBite(?event:Event):Void {
		if (!draggingBite) return;
		draggingBite = false;
		if (biteToothJob != null) biteToothJob.complete();
		var pt:Point = pattern.globalToLocal(biteTooth.localToGlobal(new Point()));
		var bX:Int = Std.int(pt.x / Layout.UNIT_SIZE) + biteTooth.endX;
		var bY:Int = Std.int(pt.y / Layout.UNIT_SIZE) + biteTooth.endY;
		if (biteTooth.endX != 0 || biteTooth.endY != 0 || !biteTooth.hitTestPoint(biteTooth.mouseX, biteTooth.mouseY)) {
			biteToothJob = KTween.to(biteTooth, Layout.QUICK, {scaleX:0.5, scaleY:0.5, alpha:0, visible:false}, Layout.POUNCE, biteTooth.reset);
		}
		endBiteCheck(bX, bY);
	}
	
	private function updateBiteTooth(event:Event):Void {
		if (draggingBite) return;
		if (biteToothJob != null) biteToothJob.complete();
		if (event.type == MouseEvent.MOUSE_OVER) {
			var tooth:Sprite = untyped __as__(event.target, Sprite);
			biteTooth.visible = true;
			biteToothJob = KTween.to(biteTooth, Layout.QUICK, {scaleX:1, scaleY:1, alpha:1}, Layout.POUNCE);
			biteTooth.x = tooth.x + Layout.BOARD_BORDER;
			biteTooth.y = tooth.y + Layout.BOARD_BORDER;
		} else {
			biteToothJob = KTween.to(biteTooth, Layout.QUICK, {scaleX:0.5, scaleY:0.5, alpha:0, visible:false}, Layout.POUNCE, biteTooth.reset);
		}
	}
}