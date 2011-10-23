import flash.Lib;
import flash.display.BitmapData;
import flash.display.BitmapDataChannel;
import flash.display.BlendMode;
import flash.display.GradientType;
import flash.display.Sprite;
import flash.display.Shape;
import flash.events.Event;
import flash.filters.BlurFilter;
import flash.geom.ColorTransform;
import flash.geom.Matrix;
import flash.geom.Rectangle;

typedef Metaball = {
	var x:Float;
	var y:Float;
	var itr:Int;
}

class Vesicle extends Sprite {

	private inline static var TWO_PI:Float = Math.PI * 2;
	private static var glob:BitmapData;
	private static var renderMat:Matrix;
	//private static var slimeCT:ColorTransform = new ColorTransform();
	private var balls:Array<Metaball>;
	private var rects:Array<Rectangle>;
	private var slimeBuffer:BitmapData;
	private var texture:BitmapData;
	private var buffer:BitmapData;
	private var gradWid:Int;
	private var texWid:Int;
	
	private var rez:Int;
	private var blurAmt:Float;
	private var blur:BlurFilter;
	private var totalFrames:Int;
	
	private var state:Array<Int>;
	private var stateWidth:Int;
	private var index:Int;
	
	private var fullCache:Array<BitmapData>;
	private var fullCacheItr:Int;
	private static var globMetaCache:Array<Array<Array<BitmapData>>> = [];
	
	private var frameItr:Int;
	private var frameSpacing:Int;
	
	private var globCache:Array<BitmapData>;
	
	public function new(
		_rez:Int, 
		_state:Array<Int>, 
		_index:Int, 
		_frames:Int, 
		_frameSpacing:Int, 
		r:Float, g:Float, b:Float,
		?baseTex:BitmapData
	):Void {
		
		super();
		totalFrames = _frames;
		state = _state;
		stateWidth = Std.int(Math.sqrt(state.length));
		index = _index;
		frameSpacing = _frameSpacing;
		
		frameItr = 0;
		
		rez = _rez;
		blurAmt = rez / 30;
		blur = new BlurFilter(blurAmt, blurAmt, 3);
		
		gradWid = Std.int(rez / 15); // 10
		
		//gradWid = Std.int(rez * 0.4); // 4
		
		texWid = Std.int(blurAmt * 2 + gradWid);
		
		if (renderMat == null) renderMat = new Matrix();
		if (glob == null) {
			glob = new BitmapData(texWid, texWid, true, 0x0);
		
			var glow:Shape = new Shape();
			var grad:Matrix = new Matrix();
			grad.createGradientBox(gradWid, gradWid, 0, blurAmt, blurAmt);
			glow.graphics.beginGradientFill(GradientType.RADIAL, [0xFF, 0xFF], [1, 0], [0x80, 0xFF], grad);
			glow.graphics.drawRect(0, 0, texWid, texWid);
			glow.graphics.endFill();
			glob.draw(glow);
			glob.applyFilter(glob, glob.rect, glob.rect.topLeft, blur);
		}
		
		if (globMetaCache[rez] == null) globMetaCache[rez] = [];
		
		globCache = globMetaCache[rez][totalFrames];
		// TODO: Maybe check for multiples of totalFrames
		if (globCache == null) {
			globCache = globMetaCache[rez][totalFrames] = [];
			
			var mat:Matrix = renderMat;
			for (i in 0...totalFrames) {
				var globFrame:BitmapData = new BitmapData(texWid, texWid, true, 0x0);
				var scale:Float = 0.86 + 0.05 * Math.sin(i / totalFrames * TWO_PI);
				mat.identity();
				mat.scale(scale, scale);
				mat.tx = mat.ty = texWid * (1 - scale) / 2;
				globFrame.draw(glob, mat, null, BlendMode.NORMAL, null, true);
				globCache.push(globFrame);
			}
			mat.identity();	 
		}
		
		
		slimeBuffer = new BitmapData(rez, rez, false, 0x0);
		buffer = new BitmapData(rez, rez, true, 0x0);
		texture = new BitmapData(rez, rez, true, 0xFFFFFFFF);
		
		texture.perlinNoise(rez * 0.1, rez * 0.1, 3, index * 10, false, true, 1, true);
		texture.colorTransform(texture.rect, new ColorTransform(r, g, b, 1, r * 40, g * 40, b * 40));
		
		if (baseTex != null) {
			baseTex = baseTex.clone();
			baseTex.draw(texture, null, null, BlendMode.ADD, null, true);
			texture.copyPixels(baseTex, texture.rect, texture.rect.topLeft);
		} else {
			blendMode = BlendMode.ADD;
		}
		
		graphics.beginBitmapFill(buffer, new Matrix(1, 0, 0, 1, 0, 0));
		graphics.drawRect(0, 0, rez, rez);
		graphics.endFill();
		
		balls = [];
		
		for (i in 0...stateWidth) {
			for (j in 0...stateWidth) {
				var sum:Int = 0;
				if (state[i * stateWidth + j] != index) continue;
				for (p in -1...2) {
					if (i + p < 0 || i + p >= stateWidth) continue;
					for (q in -1...2) {
						if (j + q < 0 || j + q >= stateWidth) continue;
						if (state[(i + p) * stateWidth + (j + q)] == index) sum++;
					}
				}
				if (sum == 9) continue;
				
				balls.push({
					x: (j + 0.5) / stateWidth * rez,
					y: (i + 0.5) / stateWidth * rez,
					itr: Std.int(Math.random() * totalFrames)
				});
			}
		}
		
		rects = [];
		var sum:Int;
		var rect:Rectangle = new Rectangle(0, 0, gradWid, gradWid);
		
		// TODO: Find any rectangles wider than and longer than one cell
		for (i in 0...stateWidth - 1) {
			for (j in 0...stateWidth - 1) {
				sum = 0;
				sum += state[i * stateWidth + j] == index ? 1 : 0;
				sum += state[i * stateWidth + j + 1] == index ? 1 : 0;
				sum += state[(i + 1) * stateWidth + j + 1] == index ? 1 : 0;
				sum += state[(i + 1) * stateWidth + j] == index ? 1 : 0;
				if (sum == 4) {
					rect.x = (j + 1) * rez / stateWidth - gradWid / 2;
					rect.y = (i + 1) * rez / stateWidth - gradWid / 2;
					rects.push(rect.clone());
				}
			}
		}
		
		fullCache = [];
		fullCacheItr = 0;
		
		prerenderGlobs();
		
		addEventListener(Event.ENTER_FRAME, render);
	}
	
	public function prerenderGlobs():Void {
		 
	}
	
	public function render(event:Event):Void {
		
		if (frameItr == 0) {
			
			if (fullCache[fullCacheItr] == null) {
				
				
				//slimeCT.blueMultiplier = Lib.current.mouseX / Lib.current.stage.stageWidth * 10;
				//slimeCT.blueOffset = Lib.current.mouseY / Lib.current.stage.stageHeight * -300;
				
				//var stamp = Lib.getTimer();
				
				var mat:Matrix = renderMat;
				
				slimeBuffer.fillRect(slimeBuffer.rect, 0x0);
				
				//var pt = new flash.geom.Point();
				//*
				for (ball in balls) {
					//trace([ball.x, ball.y]);
					mat.tx = ball.x - texWid / 2;
					mat.ty = ball.y - texWid / 2;
					slimeBuffer.draw(globCache[ball.itr], mat, null, BlendMode.ADD, null, true);
					//slimeBuffer.copyPixels(glob, glob.rect, pt);
					ball.itr = (ball.itr + 1) % totalFrames;
				}
				/**/
				
				slimeBuffer.threshold(slimeBuffer, slimeBuffer.rect, slimeBuffer.rect.topLeft, ">", 0x60, 0xFFFFFFFF, 0xFF, true);
				//slimeBuffer.colorTransform(slimeBuffer.rect, slimeCT);
				
				for (rect in rects) slimeBuffer.fillRect(rect, 0xFF0000FF);
				
				buffer.copyPixels(texture, buffer.rect, buffer.rect.topLeft);
				buffer.copyChannel(slimeBuffer, buffer.rect, buffer.rect.topLeft, BitmapDataChannel.BLUE, BitmapDataChannel.ALPHA);
				
				//flash.Lib.trace(Lib.getTimer() - stamp);
				
				fullCache[fullCacheItr] = buffer.clone();
			} else {
				buffer.copyPixels(fullCache[fullCacheItr], buffer.rect, buffer.rect.topLeft);
			}
			
			fullCacheItr = (fullCacheItr + 1) % totalFrames;
		}
		
		frameItr = (frameItr + 1) % frameSpacing;
	}

}
