package view;

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

import utils.display.Grid;

import net.kawa.tween.KTJob;
import net.kawa.tween.easing.Linear;

using net.kawa.tween.KTween;

class GameGrid extends Sprite {

	private static var BITE_GLOW:GlowFilter = new GlowFilter(0xFFFFFF, 1, 9, 9, 20, 1, true);
	private static var ORIGIN:Point = new Point();
	private static var ALPHA_BLUR:BlurFilter = new BlurFilter(10, 10, 2);

	private static var SLIME_MAKER:GlowFilter = new GlowFilter(0x0, 1, 14, 14, 2.5, 1, true);
	private static var BLUR_FILTER:BlurFilter = new BlurFilter(6, 6, 2);
	private static var GRID_BLUR:BlurFilter = new BlurFilter(4, 4, 1);

	private static var FADE_CT:ColorTransform = new ColorTransform(1, 1, 1, 0.9);

	private static var COMPLETE_EVENT:Event = new Event(Event.COMPLETE);

	public var bite:Int->Int->Int->Int->Void;
	public var space:Shape;

	private var background:Shape;
	private var content:Sprite;
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
	private var cloudCover:BitmapData;
	private var fader:Shape;
	private var biteTooth:BiteTooth;
	private var biteToothJob:KTJob;

	private var boardSize:Int;
	private var boardNumCells:Int;

	private var playerBodies:Array<Shape>;
	private var playerHeads:Array<Shape>;
	private var playerHeadTweens:Array<KTJob>;
	private var playerBitmaps:Array<BitmapData>;

	private var fadeSequence:Array<Int>;
	private var fadeJob:KTJob;
	private var fadeCount:Float;
	private var fadeMult:Float;
	private var fadeBitmapRatio:Float;
	private var fadeMatrix:Matrix;
	private var gridTeethJob:KTJob;
	private var draggingBite:Bool;
	private var biteLimits:Array<Int>;
	private var biteLimitGrid:Array<Array<Int>>;

	private var bSX:Int;
	private var bSY:Int;
	private var bEX:Int;
	private var bEY:Int;

	public function new():Void {

		super();
		draggingBite = false;

		playerHeads = [];
		playerHeadTweens = [];
		playerBodies = [];
		playerBitmaps = [];
		fadeSequence = [];

		fadeMatrix = new Matrix();

		var u:Float =  Layout.UNIT_REZ;

		boardSize = 1;
		boardNumCells = 1;

		SLIME_MAKER.blurX = SLIME_MAKER.blurY = 0.7 * u;
		BLUR_FILTER.blurX = BLUR_FILTER.blurY = 0.3 * u;
		GRID_BLUR.blurX = GRID_BLUR.blurY = 0.25 * u;

		background = new Shape();
		blurredPattern = new Shape();
		clouds = new Shape();
		fader = new Shape();

		bodies = new Sprite();
		bodies.x = bodies.y = u * -Layout.BODY_PADDING;
		bodies.transform.colorTransform = new ColorTransform(0.6, 0.6, 0.6, 3);
		bodies.blendMode = BlendMode.ADD;
		heads = new Sprite();
		heads.x = heads.y = Layout.GRID_BORDER * u;
		heads.mouseEnabled = heads.mouseChildren = false;
		space = new Shape();
		space.x = space.y = Layout.GRID_BORDER * u;
		toothPool = [];
		teeth = new Sprite();
		teeth.visible = false;
		teeth.mouseEnabled = teeth.mouseChildren = false;
		teeth.alpha = 0;
		teeth.filters = [BITE_GLOW];
		teeth.x = teeth.y = Layout.GRID_BORDER * u;
		biteTooth = new BiteTooth();

		content = new Sprite();
		content.x = content.y = Layout.GRID_BORDER * u;

		cacheAsBitmap = true;
		tabEnabled = !(buttonMode = useHandCursor = true);

		teeth.addEventListener(MouseEvent.MOUSE_DOWN, firstBite);

		teeth.addEventListener(MouseEvent.MOUSE_OVER, updateBiteTooth);
		teeth.addEventListener(MouseEvent.ROLL_OUT, updateBiteTooth);

		addEventListener(Event.ADDED_TO_STAGE, connectToStage);
	}

	public function setSize(_boardSize:Int, _boardNumCells:Int, ?circular:Bool):Void {

		boardSize = _boardSize;
		boardNumCells = _boardNumCells;

		// remove/clear existing size-specific stuff
		background.graphics.clear();
		blurredPattern.graphics.clear();
		clouds.graphics.clear();
		fader.graphics.clear();
		if (blurredPatternData != null) blurredPatternData.dispose();
		if (cloudCover != null) cloudCover.dispose();
		if (fadeSourceBitmap != null) fadeSourceBitmap.dispose();

		// make/draw new size-specific stuff
		var bmpSize:Int = Std.int(Layout.UNIT_REZ * boardSize);
		var u:Float = Layout.UNIT_REZ;

		ALPHA_BLUR.blurX = ALPHA_BLUR.blurY = 0.5 * Layout.FADE_BITMAP_REZ / boardSize;

		var bdr:Float = u * Layout.GRID_BORDER;

		if (circular) {
			GUIFactory.drawSolidCircle(background, 0x606060, 1, 0, 0, bmpSize + 2 * bdr);
			GUIFactory.drawSolidCircle(background, 0x333333, 1, 0.2 * (2 * bdr), 0.2 * (2 * bdr), bmpSize + 0.6 * (2 * bdr));
		} else {
			GUIFactory.drawSolidRect(background, 0x606060, 1, 0, 0, bmpSize + (2 * bdr), bmpSize + (2 * bdr), 0.3 * (2 * bdr));
			GUIFactory.drawSolidRect(background, 0x333333, 1, 0.2 * (2 * bdr), 0.2 * (2 * bdr), bmpSize + 0.6 * 2 * bdr, bmpSize + 0.6 * 2 * bdr, 0.2 * (2 * bdr));
		}

		if (pattern == null) {
			pattern = new Grid(Std.int(u * 2), bmpSize, bmpSize, circular ? bmpSize : u * 0.5, 0xFF111111, 0xFF222222);
		} else {
			pattern.setWidth(bmpSize);
			pattern.setHeight(bmpSize);
			pattern.setCornerRadius(circular ? bmpSize : u * 0.5);
		}

		blurredPatternData = new BitmapData(bmpSize, bmpSize, true, 0x0);
		GUIFactory.drawBitmapToShape(blurredPattern, blurredPatternData, 1, true, circular ? bmpSize : u * 0.5);
		cloudCover = new BitmapData(bmpSize, bmpSize, false, 0xFF000000);
		cloudCover.perlinNoise(1.5 * u, 1.5 * u, 3, 100, false, true, 7, true);
		cloudCover.colorTransform(cloudCover.rect, new ColorTransform(0.7, 0.7, 0.7));
		GUIFactory.drawBitmapToShape(clouds, cloudCover, 1, true, circular ? bmpSize : u * 0.5);
		clouds.blendMode = BlendMode.OVERLAY;

		var paddedBmpSize:Int = Std.int(bmpSize + 2 * u * Layout.BODY_PADDING);
		var faderBmpSize:Int = Layout.FADE_BITMAP_REZ;
		fadeBitmapRatio = faderBmpSize / paddedBmpSize;
		fadeSourceBitmap = new BitmapData(faderBmpSize, faderBmpSize, true, 0x0);
		fadeBitmap = fadeSourceBitmap.clone();
		GUIFactory.drawBitmapToShape(fader, fadeBitmap, 1, true);
		fadeAlphaBitmap = fadeSourceBitmap.clone();
		fader.x = fader.y = (Layout.GRID_BORDER - Layout.BODY_PADDING) * u;
		fader.scaleX = fader.scaleY = 1 / fadeBitmapRatio;
		biteTooth.x = biteTooth.y = bmpSize / 2;

		GUIFactory.fillSprite(content, [
			pattern,
			blurredPattern,
			bodies,
			clouds,
		]);

		GUIFactory.fillSprite(this, [
			background,
			space,
			content,
			fader,
			heads,
			teeth,
			biteTooth,
		]);

		// clear out the old bodies
		for (ike in 0...playerBitmaps.length) {
			var paddedBmpSize:Int = Std.int(u * (boardSize + 2 * Layout.BODY_PADDING));
			var bmp:BitmapData = new BitmapData(paddedBmpSize, paddedBmpSize, true, 0x0);
			var body:Shape = cast(bodies.getChildAt(ike), Shape);
			body.graphics.clear();
			GUIFactory.drawBitmapToShape(body, bmp, 1, true);
			playerBitmaps[ike].dispose();
			playerBitmaps[ike] = bmp;
		}
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

	public function tint(ct:ColorTransform):Void {
		background.transform.colorTransform = ct;
	}
	public function fade(byFreshness:Bool, arr:Array<Int>, max:Int):Void {

		if (fadeJob != null) fadeJob.complete();
		var diff:Float;
		fadeSourceBitmap.lock();
		fadeSourceBitmap.fillRect(fadeSourceBitmap.rect, 0x0);
		diff = -(Layout.GRID_BORDER - Layout.BODY_PADDING) * Layout.UNIT_REZ;
		fadeMatrix.identity();
		fadeMatrix.translate(diff, diff);
		fadeMatrix.scale(fadeBitmapRatio, fadeBitmapRatio);
		fadeSourceBitmap.draw(background, fadeMatrix, background.transform.colorTransform, BlendMode.NORMAL, null, true);

		diff = Layout.UNIT_REZ * Layout.BODY_PADDING;
		fadeMatrix.identity();
		fadeMatrix.translate(diff, diff);
		fadeMatrix.scale(fadeBitmapRatio, fadeBitmapRatio);
		fadeSourceBitmap.draw(content, fadeMatrix, null, BlendMode.NORMAL, null, true);
		fadeSourceBitmap.unlock();
		// Sequence the changed indices

		fadeCount = 0;
		fadeSequence.splice(0, fadeSequence.length);

		if (byFreshness) {
			var fadeSequences:Array<Array<Int>> = [];
			for (ike in 0...boardNumCells) {
				var freshness:Int = arr[ike] - 1;
				if (freshness >= 0) {
					var seq:Array<Int> = fadeSequences[freshness];
					if (seq == null) seq = fadeSequences[freshness] = [];
					seq.push(ike);
				}
			}
			for (seq in fadeSequences) {
				if (seq == null) continue;
				seq.sort(randSort);
				fadeSequence = fadeSequence.concat(seq);
			}

			fadeMult = 10 + fadeSequence.length / boardNumCells * 90;

			fadeJob = this.to(Math.log(fadeSequence.length) * 0.2, {fadeCount:fadeSequence.length + fadeMult / 2}, Linear.easeOut, fadeComplete);
		} else {
			fadeBitmap.copyPixels(fadeSourceBitmap, fadeSourceBitmap.rect, ORIGIN);
			fadeJob = this.to(Layout.QUICK * 3, {fadeCount:1}, Linear.easeOut, fadeComplete);
		}

		fadeJob.onChange = fadeUpdate;
		fadeUpdate();
		fader.visible = true;
	}

	public function makePlayerHeadAndBody():Void {

		var paddedBmpSize:Int = Std.int(Layout.UNIT_REZ * (boardSize + 2 * Layout.BODY_PADDING));

		var bmp:BitmapData = new BitmapData(paddedBmpSize, paddedBmpSize, true, 0x0);
		playerBitmaps.push(bmp);

		var body:Shape = GUIFactory.drawBitmapToShape(new Shape(), bmp, 1, true);
		var head:Shape = GUIFactory.makeHead(Layout.UNIT_REZ);
		head.x = head.y = paddedBmpSize * 0.5;

		playerBodies.push(body);
		bodies.addChild(body);
		playerHeads.push(head);
		heads.addChild(head);
	}

	public function updateBodies(bodyGrid:Array<Int>):Void {

		var len:Int = boardNumCells;
		var rect:Rectangle = new Rectangle(0, 0, Layout.UNIT_REZ, Layout.UNIT_REZ);
		var rx:Int, ry:Int;

		preparePlayerBitmaps();

		for (bmp in playerBitmaps) bmp.lock();

		for (ike in 0...len) {
			if (bodyGrid[ike] > 0) {
				rx = ike % boardSize;
				ry = Std.int((ike - rx) / boardSize);
				rect.x = (rx + Layout.BODY_PADDING) * Layout.UNIT_REZ;
				rect.y = (ry + Layout.BODY_PADDING) * Layout.UNIT_REZ;
				playerBitmaps[bodyGrid[ike] - 1].fillRect(rect, 0xFFFFFFFF);
			}
		}

		for (bmp in playerBitmaps) bmp.unlock();

		finishPlayerBitmaps();
	}

	public function updateHeads(players:Array<Player>):Void {
		for (ike in 0...players.length) {
			var head:Shape = playerHeads[ike];
			if (playerHeadTweens[ike] != null) playerHeadTweens[ike].close();
			playerHeadTweens[ike] = null;
			if (players[ike].alive && head.alpha < 1) {
				head.visible = true;
				playerHeadTweens[ike] = head.to(Layout.QUICK * 5, {scaleX:1, scaleY:1, alpha:1}, Linear.easeOut);
			} else if (!players[ike].alive && head.alpha > 0) {
				playerHeadTweens[ike] = head.to(Layout.QUICK * 5, {scaleX:1, scaleY:1, alpha:0, visible:false}, Linear.easeOut);
			}
		}
	}

	public function init(players:Array<Player>, cts:Array<ColorTransform>):Void {
		for (ike in 0...Common.MAX_PLAYERS) {
			var head:Shape = playerHeads[ike];
			if (ike < players.length) {
				head.visible = true;
				head.alpha = 1;
				head.x = (players[ike].headX + 0.5) * Layout.UNIT_REZ;
				head.y = (players[ike].headY + 0.5) * Layout.UNIT_REZ;
				head.transform.colorTransform = cts[players[ike].color];
				playerBodies[ike].transform.colorTransform = cts[players[ike].color];
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
		gridTeethJob = teeth.to(Layout.QUICK * 2, {alpha:1}, Layout.POUNCE);
	}

	public function hideTeeth(playerIndex:Int):Void {
		if (gridTeethJob != null) gridTeethJob.close();
		if (biteToothJob != null) biteToothJob.close();
		draggingBite = false;
		teeth.mouseEnabled = teeth.mouseChildren = false;
		gridTeethJob = teeth.to(Layout.QUICK * 2, {alpha:0, visible:false}, Layout.POUNCE);
		biteToothJob = biteTooth.to(Layout.QUICK, {scaleX:0.5, scaleY:0.5, alpha:0, visible:false}, Layout.POUNCE, biteTooth.reset);
		playerHeads[playerIndex].visible = true;
	}

	public function updateTeeth(br:Array<Array<Int>>, index:Int, headX:Int, headY:Int, ct:ColorTransform):Void {

		if (br == null) br = [];

		var head:Shape = playerHeads[index];
		var bx:Int, by:Int;
		var totalTeeth:Int = teeth.numChildren;
		var tooth:Sprite;
		var toothItr:Int = 0;

		var arr:Array<Int> = [];
		for (ike in 0...br.length) {
			if (br[ike] == null) continue;
			by = Std.int(ike / boardSize);
			bx = ike - by * boardSize;
			if (bx == headX && by == headY) head.visible = false;
			if (toothItr > toothPool.length - 1) {
				tooth = GUIFactory.makeTooth(Layout.UNIT_REZ * 1.25);
				toothPool.push(tooth);
			} else {
				tooth = toothPool[toothItr];
				tooth.visible = true;
			}

			tooth.transform.colorTransform = ct;
			tooth.x = (bx + 0.5) * Layout.UNIT_REZ;
			tooth.y = (by + 0.5) * Layout.UNIT_REZ;
			teeth.addChild(tooth);

			toothItr++;
		}
		for (ike in toothItr...toothPool.length) toothPool[ike].visible = false;
		biteLimitGrid = br;
	}

	public function isDraggingBite():Bool { return draggingBite; }

	private function randSort(one:Int, two:Int):Int {
		return Math.random() > 0.5 ? 1 : -1;
	}

	private function fadeUpdate():Void {
		if (fadeSequence.length > 0) {

			fadeBitmap.lock();
			fadeBitmap.fillRect(fadeBitmap.rect, 0x0);
			fadeAlphaBitmap.fillRect(fadeAlphaBitmap.rect, 0xFFFFFFFF);

			// draw the patches to fadeAlphaBitmap

			var rect:Rectangle = new Rectangle();
			var totalRect:Rectangle = null;
			var u:Float = Layout.UNIT_REZ * fadeBitmapRatio;

			rect.width = rect.height = 2 * u;

			var ike:Int = Std.int(Math.min(fadeCount, fadeSequence.length - 1));

			while (ike >= 0) {
				var val:Float = (fadeMult - Math.min(fadeMult, fadeCount - ike)) / fadeMult;
				var alpha:Int = Std.int(0xFF * val * val);
				var index:Int = fadeSequence[ike];
				var tx:Int = (index % boardSize);
				var ty:Int = Std.int((index - tx) / boardSize);
				rect.x = (tx + Layout.BODY_PADDING - 0.5) * u;
				rect.y = (ty + Layout.BODY_PADDING - 0.5) * u;
				if (totalRect == null) {
					totalRect = rect.clone();
				} else {
					totalRect = totalRect.union(rect);
				}
				fadeAlphaBitmap.fillRect(rect, alpha | 0xFFFFFF00);
				ike--;
			}

			if (totalRect != null) {
				if (totalRect.containsRect(fadeAlphaBitmap.rect)) totalRect = fadeAlphaBitmap.rect;
				fadeAlphaBitmap.applyFilter(fadeAlphaBitmap, totalRect, totalRect.topLeft, ALPHA_BLUR);
			}

			fadeBitmap.copyPixels(fadeSourceBitmap, fadeSourceBitmap.rect, ORIGIN);
			fadeBitmap.copyChannel(fadeAlphaBitmap, fadeAlphaBitmap.rect, ORIGIN, BitmapDataChannel.BLUE, BitmapDataChannel.ALPHA);

			fadeBitmap.unlock();
		} else {
			fadeBitmap.colorTransform(fadeBitmap.rect, FADE_CT);
		}
	}

	private function fadeComplete():Void {
		fader.visible = false;
		dispatchEvent(COMPLETE_EVENT);
	}

	private function preparePlayerBitmaps():Void {
		for (ike in 0...Common.MAX_PLAYERS) playerBitmaps[ike].fillRect(playerBitmaps[ike].rect, 0x0);
	}

	private function finishPlayerBitmaps():Void {
		var bmp:BitmapData;
		var bmpSize:Int = Std.int(Layout.UNIT_REZ * (boardSize + 2 * Layout.GRID_BORDER));
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
		mat.tx = -space.x;
		mat.ty = -space.y;
		for (ike in 0...Common.MAX_PLAYERS) bmp2.draw(playerBitmaps[ike], mat, null, BlendMode.ADD);
		blurredPatternData.draw(pattern);
		blurredPatternData.applyFilter(blurredPatternData, blurredPatternData.rect, ORIGIN, GRID_BLUR);
		blurredPatternData.copyChannel(bmp2, bmp2.rect, ORIGIN, BitmapDataChannel.RED, BitmapDataChannel.ALPHA);
		bmp2.dispose();
	}

	public function fillBoardRandomly(?event:Event):Void {
		var bmp:BitmapData;
		var whatev:Array<Array<Null<Bool>>> = [];
		var rect:Rectangle = new Rectangle();
		var total:Int = Std.int(boardNumCells / Common.MAX_PLAYERS);

		preparePlayerBitmaps();

		for (bmp in playerBitmaps) {
			for (ike in 0...total) {
				var rx:Int = 0;
				var ry:Int = 0;
				while (true) {
					rx = Std.int(Math.random() * boardSize) * Std.int(Layout.UNIT_REZ);
					ry = Std.int(Math.random() * boardSize) * Std.int(Layout.UNIT_REZ);
					if (whatev[ry] == null) whatev[ry] = [];
					if (whatev[ry][rx] == null) {
						whatev[ry][rx] = true;
						break;
					}
				}
				rect.x = rx + Layout.BODY_PADDING * Layout.UNIT_REZ;
				rect.y = ry + Layout.BODY_PADDING * Layout.UNIT_REZ;
				rect.width = rect.height = Layout.UNIT_REZ;
				bmp.fillRect(rect, 0xFFFFFFFF);
			}
		}

		finishPlayerBitmaps();
	}

	private function firstBite(?event:Event):Void {
		if (draggingBite) return;
		draggingBite = true;
		bSX = Std.int(teeth.mouseX / Layout.UNIT_REZ);
		bSY = Std.int(teeth.mouseY / Layout.UNIT_REZ);
		biteLimits = biteLimitGrid[bSY * boardSize + bSX];
	}

	private function dragBite():Void {

		var dX:Int = Std.int(biteTooth.mouseX / Layout.UNIT_REZ);
		var dY:Int = Std.int(biteTooth.mouseY / Layout.UNIT_REZ);
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

		var min:Int = horiz ? biteLimits[0] : biteLimits[1];
		var max:Int = horiz ? biteLimits[2] : biteLimits[3];
		var val:Int = horiz ? dX : dY;

		biteTooth.stretchTo(Std.int(Math.max(min, Math.min(val, max))), horiz);
	}

	private function endBite(?event:Event):Void {
		if (!draggingBite) return;
		draggingBite = false;
		if (biteToothJob != null) biteToothJob.complete();
		var pt:Point = space.globalToLocal(biteTooth.localToGlobal(new Point()));
		bEX = Std.int(pt.x / Layout.UNIT_REZ) + biteTooth.endX;
		bEY = Std.int(pt.y / Layout.UNIT_REZ) + biteTooth.endY;
		if (biteTooth.endX != 0 || biteTooth.endY != 0 || !biteTooth.hitTestPoint(stage.mouseX, stage.mouseY)) {
			biteToothJob = biteTooth.to(Layout.QUICK, {scaleX:0.5, scaleY:0.5, alpha:0, visible:false}, Layout.POUNCE, biteTooth.reset);
		}
		bite(bSX, bSY, bEX, bEY);
	}

	private function updateBiteTooth(event:Event):Void {
		if (draggingBite) return;
		if (biteToothJob != null) biteToothJob.complete();
		if (event.type == MouseEvent.MOUSE_OVER) {
			var tooth:Sprite = untyped __as__(event.target, Sprite);
			biteTooth.visible = true;
			biteToothJob = biteTooth.to(Layout.QUICK, {scaleX:1, scaleY:1, alpha:1}, Layout.POUNCE);
			biteTooth.x = tooth.x + Layout.GRID_BORDER * Layout.UNIT_REZ;
			biteTooth.y = tooth.y + Layout.GRID_BORDER * Layout.UNIT_REZ;
		} else {
			biteToothJob = biteTooth.to(Layout.QUICK, {scaleX:0.5, scaleY:0.5, alpha:0, visible:false}, Layout.POUNCE, biteTooth.reset);
		}
	}
}
