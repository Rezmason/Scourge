package metaball;

import flash.display.BitmapData;
import flash.display.GradientType;
import flash.display.Shape;
import flash.events.Event;
import flash.filters.BlurFilter;
import flash.geom.Matrix;
import flash.geom.Rectangle;
import flash.Lib;
import haxe.macro.Expr;

import buffer.Assert;
import buffer.Grade;
import buffer.Buffer;

/**
 * ...
 * @author
 */

typedef Metaball = {
	var x:Float;
	var y:Float;
	var itr:Int;
}

class CleanVesicle extends Shape {

	//private var rects:Array<Rectangle>;

	private var texWid:Int;
	private var frameWid:Int;
	private var activeWid:Int;
	private var frames:Int;

	private var state:Array<Metaball>;
	private var stateWidth:Int;

	private static var accumBuffers:Array<Buffer>;
	private var accumBuffer:Buffer;
	private var ballBuffers:Array<Buffer>;
	private var lookupTable:Buffer;
	private static var defaultLookupTable:Buffer;

	public var frameBuffer(default, null):Buffer;
	public var output(default, null):BitmapData;

	public function new(
		_ballBuffers:Array<Buffer>,
		_texWid:Int,
		_frameWid:Int,
		_lookupTable:Buffer,
		_base:BitmapData,
		?_state:Array<Metaball>,
		?_frames:Int = 30
	):Void {

		super();

		#if debug
		new TDD (); //Tests
		#end

		texWid = _texWid;
		ballBuffers = _ballBuffers;

		if (ballBuffers == null || ballBuffers.length == 0) {

			ballBuffers = [];

			var ball:Shape = new Shape();
			ball.graphics.beginFill(0xFF);
			ball.graphics.drawCircle(texWid / 2, texWid / 2, texWid / 4);
			ball.graphics.endFill();

			var ballData:BitmapData = new BitmapData(texWid, texWid, true, 0x0);
			ballData.draw(ball);

			ballBuffers.push(Buffer.fromBitmapAlpha(ballData));
		}

		frameWid = _frameWid;
		activeWid = frameWid - texWid;
		lookupTable = _lookupTable;

		if (lookupTable == null) {
			if (defaultLookupTable == null) {
				var gradient:Array<GradientEntry> = [
					{ratio:0., value:0., duplicate:false},
					{ratio:1., value:1., duplicate:false},
				];
				defaultLookupTable = Grade.generateLookupTable(gradient, 0xFF, 0xFF, 25600);
			}
			lookupTable = defaultLookupTable;
		}

		frameBuffer = Buffer.fromBitmap(_base, frameWid, frameWid);

		var accumSize:Int = frameWid * frameWid * 4;

		if (accumBuffers == null) accumBuffers = [];
		accumBuffer = accumBuffers[accumSize];
		if (accumBuffer == null) accumBuffers[accumSize] = accumBuffer = Buffer.allocate(accumSize);

		output = new BitmapData(frameWid, frameWid, true);

		graphics.lineStyle(0, 0xFF0000);
		graphics.beginBitmapFill(output, new Matrix(1, 0, 0, 1, 0, 0), false, true);
		graphics.drawRect(0, 0, frameWid, frameWid);
		graphics.endFill();
		graphics.lineStyle(0, 0x00FF00);
		graphics.drawRect(texWid / 2, texWid / 2, activeWid, activeWid);

		addEventListener(Event.ADDED, update);

		adjust(_state, _frames);
	}

	public function ready():Void
	{
		graphics.clear();
		graphics.beginBitmapFill(output, new Matrix(1, 0, 0, 1, 0, 0), false, true);
		graphics.drawRect(0, 0, frameWid, frameWid);
		graphics.endFill();
	}

	public function adjust(?_state:Array<Metaball>, ?_frames:Int = -1):Void {
		if (_frames > 0 && frames != _frames) frames = _frames;

		if (_state != state) {
			state = _state;
			if (state != null) {
				stateWidth = Std.int(Math.sqrt(state.length));
				validateState(state, this);
			}
		}

		update();
	}

	public function update(?event:Event):Void {

		if (state == null) return;

		var tm:Array<Int> = [];
		tm.push(Lib.getTimer());
		clearBuffer (accumBuffer, 0x00000000);

		var offset:Int = 0;
		var mult:Int = activeWid;
		var len:Int = ballBuffers.length;

		for (ball in state) {
			addBlendBlitAlphaChannel (
				accumBuffer, frameWid, frameWid,
				ballBuffers[ball.itr], texWid, texWid,
				Std.int(ball.x * mult) + offset, Std.int(ball.y * mult) + offset
			);

			ball.itr = (ball.itr + 1) % len;
		}

		tm.push(Lib.getTimer());
		filterBuffer(accumBuffer, frameBuffer, lookupTable);
		tm.push(Lib.getTimer());

		if (stage != null) {
			Buffer.draw (output, frameBuffer);
		}

		tm.push(Lib.getTimer());

		var df:Array<Int> = [];
		for (i in 0...tm.length - 1) df.push(tm[i + 1] - tm[i]);
		//Lib.trace("U: " + df);
	}

	public static function validateState(_state:Array<Metaball>, ves:CleanVesicle):Bool {
		var passedInspection:Bool = true;
		for (ball in _state) {
			if (ball.itr >= ves.ballBuffers.length) {
				passedInspection = false;
				ball.itr = ves.ballBuffers.length - 1;
			}
			if (ball.x < 0 || ball.x > 1) {
				passedInspection = false;
				ball.x = 0.5;
			}
			if (ball.y < 0 || ball.y > 1) {
				passedInspection = false;
				ball.y = 0.5;
			}
		}
		return passedInspection;
	}

	static inline function addBlendBlitAlphaChannel (
				buffer:Buffer, bfrWidth:Int, bfrHeight:Int,
				sprite:Buffer, sprWidth:Int, sprHeight:Int,
				x:Int, y:Int):Void {

		#if debug

		Assert.equals(sprWidth * sprHeight, sprite.size);
		Assert.equals(bfrWidth * bfrHeight * 4, buffer.size);

		#end

		var start_addr:Int = buffer.start + ((y * bfrWidth) + x) * 4;	//argb
		var fb_jump:Int = (bfrWidth - sprWidth) * 4;
		var end_addr:Int = ( (sprHeight * bfrWidth) * 4 ) + start_addr;
		var spr_addr:Int = sprite.start;

		while ( start_addr < end_addr )
		{
			var row_end_addr:Int = start_addr + (sprWidth * 4);

			while ( start_addr < row_end_addr )
			{
				var spv:Int = sprite.getByte (spr_addr);
				var bpv:Int = buffer.getI32 (start_addr);

				var comb:Int = spv + bpv;
				buffer.setI32 (start_addr, comb);


				start_addr += 4;  spr_addr ++;

			}

			start_addr += fb_jump;
		}
	}

	/**
	 * Obliterates Alpha channel of frameBuffer
	 * @param	src
	 * @param	dst
	 * @param	lookupTable
	 */
	public static function filterBuffer(src:Buffer, dst:Buffer, lookupTable:Buffer)
	{
		#if debug
		Assert.equals (src.size, dst.size);
		#end

		var ib_start:Int = src.start;

		var fb_start:Int = dst.start;
		var fb_end:Int = dst.end;

		var lut_start:Int = lookupTable.start;

		while (fb_start < fb_end) {

			var ibl:UInt;
			var lutv:UInt;

			ibl = src.getI32 (ib_start);

			lutv = lookupTable.getByte (lut_start + ibl);

			dst.setByte (fb_start, lutv);		//Writes Alpha channel (remember endian-ness)

			fb_start += 4;
			ib_start += 4;
		}
	}

	//CONFIRMED - BGRA
	public static function clearBuffer (buffer:Buffer, color:UInt) {
		var addr:Int = buffer.start;
		var eaddr:Int = buffer.end;

		while (addr < eaddr) {
			buffer.setI32 (addr, color);

			addr += 4;
		}
	}
}

#if debug

class TDD
{
	public function new( )
	{
		test_clearBuffer ();
		test_filterBuffer();
	}

	function test_filterBuffer()
	{
	}

	function test_clearBuffer ()
	{
		var b:Buffer = Buffer.allocate (4);
		CleanVesicle.clearBuffer (b, 0xFFFF0000);
		Assert.equals (0xFFFF0000, b.getI32 (b.start));
	}
}

#end
