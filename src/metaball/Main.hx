package metaball;

import flash.Lib;
import com.remixtechnology.SWFProfiler;

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.BlendMode;
import flash.display.GradientType;
import flash.display.Shape;
import flash.display.Sprite;
import flash.events.Event;
import flash.filters.BlurFilter;
import flash.geom.ColorTransform;
import flash.geom.Rectangle;
import flash.geom.Matrix;

import haxe.Timer;

import buffer.Buffer;
import buffer.Grade;
import metaball.CleanVesicle;

import net.rezmason.flash.display.Grid;

typedef RGB = {
	var r:Float;
	var g:Float;
	var b:Float;
}

class Main {

	private static var fourSquares:Array<Int> = [
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 4, 4, 4, 4, 4, 4, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 4, 4, 4, 4, 4, 4, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 4, 4, 4, 4, 4, 4, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 4, 4, 4, 4, 4, 4, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 4, 4, 4, 4, 4, 4, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 4, 4, 4, 4, 4, 4, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	];

	private static var spiral:Array<Int> = [
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 2, 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 3, 3, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 3, 1, 1, 3, 3, 3, 3, 3, 3, 1, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 3, 1, 3, 3, 1, 1, 1, 1, 3, 1, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 3, 1, 3, 1, 1, 3, 3, 1, 3, 1, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 3, 1, 3, 1, 1, 3, 3, 1, 3, 1, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 3, 1, 3, 3, 3, 3, 1, 1, 3, 1, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 3, 1, 1, 1, 1, 1, 1, 3, 3, 1, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 3, 3, 3, 3, 3, 3, 3, 3, 1, 1, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4, 4, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	];

	private static var oaf:Array<Int> = [
	1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
	1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
	1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
	1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
	1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
	1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 1, 1, 1, 1, 1,
	1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 1, 1, 1, 1, 1,
	1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 1, 1, 1, 1, 1,
	1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 1, 1, 1, 1, 1,
	1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 1, 1, 1, 1, 1,
	1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 1, 1, 1, 1, 1,
	1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4, 4, 4, 4, 4, 4, 1, 1, 1, 1, 1,
	1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4, 4, 4, 4, 4, 4, 1, 1, 1, 1, 1,
	1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4, 4, 4, 4, 4, 4, 1, 1, 1, 1, 1,
	1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4, 4, 4, 4, 4, 4, 1, 1, 1, 1, 1,
	1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 4, 4, 4, 4, 4, 4, 1, 1, 1, 1, 1,
	1, 1, 1, 1, 1, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 1, 1, 1, 1, 1,
	1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
	1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
	1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
	1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
	1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
	];

	private static var twoPlayer:Array<Int> = [
	0, 1, 1, 2, 2, 2, 2, 2, 2, 0, 2, 2, 2, 0, 0, 0, 0, 0,
	0, 1, 1, 1, 2, 2, 2, 0, 2, 2, 2, 0, 2, 0, 0, 0, 0, 0,
	1, 1, 0, 1, 0, 2, 2, 2, 0, 2, 2, 2, 2, 0, 0, 0, 0, 0,
	1, 0, 0, 1, 1, 2, 0, 2, 2, 2, 0, 0, 2, 0, 0, 0, 0, 0,
	1, 1, 1, 1, 1, 2, 2, 2, 0, 2, 2, 2, 0, 0, 0, 0, 0, 0,
	1, 1, 1, 0, 1, 2, 0, 2, 2, 0, 0, 2, 2, 0, 0, 0, 0, 0,
	0, 1, 0, 0, 1, 0, 2, 2, 0, 2, 2, 2, 2, 0, 0, 0, 0, 0,
	1, 1, 1, 1, 1, 0, 2, 2, 0, 2, 2, 0, 2, 0, 2, 0, 0, 0,
	1, 1, 0, 1, 1, 0, 0, 2, 2, 0, 2, 2, 2, 0, 2, 0, 0, 0,
	1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 0, 2, 0, 2, 0, 0, 0,
	1, 0, 1, 1, 1, 0, 1, 1, 1, 2, 2, 2, 2, 2, 2, 0, 0, 0,
	1, 0, 1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 2, 2, 2, 2, 2, 0,
	1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 0, 2, 2, 0, 0, 2, 2,
	1, 0, 0, 1, 1, 0, 1, 1, 1, 1, 1, 1, 0, 2, 2, 2, 0, 2,
	0, 0, 0, 0, 1, 1, 1, 0, 1, 1, 1, 0, 2, 2, 2, 2, 2, 2,
	0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 1, 1, 0, 2, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 1, 0, 2, 2, 2, 2, 2,
	0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 2, 2, 0, 0, 2, 2,
	];

	private static var twoPlayerLife:Array<Int> = [
	0,  17, 16, 15, 14, 13, 12, 11, 10, 0,  10, 11, 12, 0,  0,  0,  0,  0,
	0,  16, 15, 14, 13, 12, 11, 0,  9,  8,  9,  0,  11, 0,  0,  0,  0,  0,
	16, 17, 0,  13, 0,  11, 10, 9,  0,  7,  8,  9,  10, 0,  0,  0,  0,  0,
	15, 0,  0,  12, 11, 12, 0,  8,  7,  6,  0,  0,  11, 0,  0,  0,  0,  0,
	14, 13, 12, 11, 10, 11, 10, 9,  0,  5,  4,  3,  0,  0,  0,  0,  0,  0,
	13, 12, 13, 0,  9,  12, 0,  10, 11, 0,  0,  2,  1,  0,  0,  0,  0,  0,
	0,  11, 0,  0,  8,  0,  12, 11, 0,  5,  4,  3,  2,  0,  0,  0,  0,  0,
	11, 10, 9,  8,  7,  0,  13, 12, 0,  6,  5,  0,  3,  0,  11, 0,  0,  0,
	10, 9,  0,  7,  6,  0,  0,  11, 10, 0,  6,  5,  4,  0,  10, 0,  0,  0,
	9,  8,  7,  6,  5,  6,  7,  8,  9,  8,  7,  0,  5,  0,  9,  0,  0,  0,
	8,  0,  6,  5,  4,  0,  8,  9,  8,  9,  8,  7,  6,  7,  8,  0,  0,  0,
	7,  0,  5,  0,  3,  0,  0,  0,  7,  0,  0,  0,  7,  8,  9,  10, 11, 0,
	6,  5,  4,  3,  2,  1,  2,  0,  6,  7,  8,  0,  8,  9,  0,  0,  12, 13,
	7,  0,  0,  4,  3,  0,  3,  4,  5,  6,  7,  8,  0,  10, 11, 12, 0,  14,
	0,  0,  0,  0,  4,  5,  4,  0,  6,  7,  8,  0,  12, 11, 12, 13, 14, 15,
	0,  0,  0,  0,  0,  0,  0,  8,  7,  0,  9,  10, 0,  12, 0,  0,  0,  0,
	0,  0,  0,  0,  0,  0,  0,  9,  8,  9,  0,  11, 0,  13, 14, 15, 16, 17,
	0,  0,  0,  0,  0,  0,  0,  10, 9,  10, 11, 12, 15, 14, 0,  0,  17, 18,
	];

	private static var tiny:Array<Int> = [
		0, 0, 0, 0,
		0, 1, 1, 0,
		0, 1, 1, 0,
		0, 0, 0, 0,
	];

	private static var cross:Array<Int> = [
		1, 1, 2, 2,
		0, 1, 2, 0,
		0, 2, 1, 0,
		2, 2, 1, 1,
	];

	private inline static var TWO_PI:Float = 2 * Math.PI;

	private static var vesicles:Array<CleanVesicle>;

	public static function main() {
		SWFProfiler.init();
		//SWFProfiler.show();

		var scene:Sprite = new Sprite();
		Lib.current.addChild(scene);

		var level:Array<Int> = null;
		var levelLife:Array<Int> = null;

		level = twoPlayer;
		levelLife = twoPlayerLife;

		var cellWidth:Int = 25;
		var growthOffset:Int = 22;
		var dotWidth:Int = cellWidth + 2 * growthOffset;
		var boardNumCells:Int = Std.int(Math.sqrt(level.length));
		var boardWidth:Int = boardNumCells * cellWidth;
		var bufferWidth:Int = boardWidth + dotWidth;
		var numFrames:Int = 60;
		var ballBlur:Int = 20;

		var grid:Grid = new Grid(2 * cellWidth, boardWidth, boardWidth, 0, 0xFF111111, 0xFF222222);

		var blurredGrid:BitmapData = new BitmapData(bufferWidth, bufferWidth, false, 0x0);
		blurredGrid.draw(grid, new Matrix(1, 0, 0, 1, dotWidth / 2, dotWidth / 2));
		var blurAmt:Float = 2;
		var gridBlur:BlurFilter = new BlurFilter(blurAmt, blurAmt, 3);
		blurredGrid.applyFilter(blurredGrid, blurredGrid.rect, blurredGrid.rect.topLeft, gridBlur);

		var gradient:Array<GradientEntry> = [
			{ratio:0.00, value:0.0, duplicate:false},
			{ratio:0.21, value:0.4, duplicate:false},
			{ratio:0.23, value:1.0, duplicate:false},
			{ratio:1.00, value:1.0, duplicate:false},
		];

		var alphaLookup:Buffer = Grade.generateLookupTable(gradient, 0xFF, 0xFF, 25600);

		var rgbs:Array<RGB> = [
			{r:1.00, g:0.00, b:0.56},
			{r:1.00, g:0.78, b:0.00},
			{r:0.18, g:1.00, b:0.00},
			{r:0.00, g:0.75, b:1.00},
		];

		var boardTexture:BitmapData = new BitmapData(boardWidth, boardWidth, false);
		boardTexture.perlinNoise(40, 40, 4, 100, false, true, 7, true);
		boardTexture.colorTransform(boardTexture.rect, new ColorTransform(4, 4, 4, 1, -300, -300, -300));
		boardTexture.draw(grid, null, null, BlendMode.MULTIPLY);

		boardTexture.applyFilter(boardTexture, boardTexture.rect, boardTexture.rect.topLeft, gridBlur);
		scene.addChild(new Bitmap(boardTexture));

		var ballBuffers:Array<Buffer> = makeBallBuffers(cellWidth, dotWidth, numFrames, ballBlur, pulseCycle);

		var vesicleContainer:Sprite = new Sprite();
		vesicleContainer.x = vesicleContainer.y = -dotWidth / 2;
		scene.addChild(vesicleContainer);

		var vBuffers:Array<Buffer> = [];
		vesicles = [];

		for (i in 0...4) {
			var state:Array<Metaball> = levelToState(level, i + 1, numFrames, levelLife);
			var texture:BitmapData = makeTexture(bufferWidth, i, rgbs[i], blurredGrid);
			var vesicle:CleanVesicle = new CleanVesicle(ballBuffers, dotWidth, bufferWidth, alphaLookup, texture, state, 30);
			vesicles.push(vesicle);
			vBuffers.push(vesicle.frameBuffer);
			vesicle.ready();
			vesicleContainer.addChild(vesicle);
		}

		scene.addEventListener(Event.ENTER_FRAME, updateVesicles);

		scene.x = (scene.stage.stageWidth  - boardWidth) / 2;
		scene.y = (scene.stage.stageHeight - boardWidth) / 2;
		//*
		var graph:Sprite = new Sprite();
		Lib.current.addChild(graph);
		graph.graphics.lineStyle(0, 0xFFFFFF);
		graph.graphics.moveTo(0, 200);
		for (i in 0...200) {
			graph.graphics.lineTo(i, 200 - pulseCycle(i / 200) * 200);
		}
		/**/
	}

	private static function updateVesicles(?event:Event):Void {
		//for (vesicle in vesicles) vesicle.update();
		vesicles[0].update();
	}

	private static function makeTexture(rez:Int, seed:Int, rgb:RGB, topTex:BitmapData):BitmapData {
		var texture:BitmapData = new BitmapData(rez, rez, true, 0xFFFFFFFF);

		texture.perlinNoise(rez * 0.1, rez * 0.1, 3, seed * 10, false, true, 1, true);
		texture.colorTransform(texture.rect, new ColorTransform(rgb.r, rgb.g, rgb.b, 1, rgb.r * 70, rgb.g * 70, rgb.b * 70));

		topTex = topTex.clone();
		topTex.draw(texture, null, null, BlendMode.ADD, null, true);
		texture.copyPixels(topTex, texture.rect, texture.rect.topLeft);

		return texture;
	}

	private static function levelToState(level:Array<Int>, index:Int, numFrames:Int, ?levelLife:Array<Int>):Array<Metaball> {
		var state:Array<Metaball> = [];
		var stateWidth:Int = Std.int(Math.sqrt(level.length));
		var maxLife:Float = 0;
		if (levelLife != null) {
			for (i in levelLife) maxLife = Math.max(maxLife, i);
		}
		for (i in 0...stateWidth) {
			for (j in 0...stateWidth) {
				if (level[i * stateWidth + j] != index) continue;
				state.push({
					x:(j + 0.5) / stateWidth,
					y:(i + 0.5) / stateWidth,
					itr:(levelLife == null ? 0 : Std.int(numFrames * 0.3 * (1 - levelLife[i * stateWidth + j] / maxLife))),
					});
			}
		}

		return state;
	}

	private static function makeBallBuffers(diameter:Int, bufferSize:Int, length:Int, blurAmt:Int, cycle:Cycle):Array<Buffer> {
		var radius:Float = diameter / 2;

		var bmd:BitmapData = new BitmapData(bufferSize, bufferSize, true, 0x0);
		var buffers:Array<Buffer> = [];

		var blur:BlurFilter = new BlurFilter(blurAmt, blurAmt, 3);

		var ball:Shape = new Shape();
		var grad:Matrix = new Matrix();
		grad.createGradientBox(diameter, diameter, 0, -radius, -radius);
		ball.graphics.beginGradientFill(GradientType.RADIAL, [0xFF, 0xFF], [1, 0], [0x80, 0xFF], grad);
		ball.graphics.drawCircle(0, 0, radius);
		ball.graphics.endFill();

		var mat:Matrix = new Matrix();
		mat.tx = mat.ty = bufferSize / 2;
		var frameToRatio:Float = 1 / length;

		var jiggle:Float = 0.08;

		var minScale:Float = 100;
		var maxScale:Float = -100;

		for (i in 0...length) {
			bmd.fillRect(bmd.rect, 0x0);

			var scale:Float = 1;

			if (length != 1) scale = (1 - jiggle) + jiggle * (cycle(i * frameToRatio) * 2 - 1);


			mat.a = mat.d = scale;
			bmd.draw(ball, mat);
			bmd.applyFilter(bmd, bmd.rect, bmd.rect.topLeft, blur);
			buffers.push(Buffer.fromBitmapAlpha(bmd, bufferSize, bufferSize));
		}

		return buffers;
	}

	private static function sineCycle(val:Float):Float {
		return 0.5 * (1 - Math.cos(val * TWO_PI));
	}

	private static function linearCycle(val:Float):Float {
		return val;
	}

	private static function pulseCycle(val:Float):Float {
		if (val < 0.125) {
			return 0.25 + 0.25 * Math.cos(TWO_PI * (val - 0.125) * 4);
		} else if (val < 0.5) {
			return 0.25 + 0.25 * Math.cos(TWO_PI * (val - 0.125) * 4 / 3);
		} else {
			return 0;
		}
		return 0;
	}
}

typedef Cycle = Float->Float;
