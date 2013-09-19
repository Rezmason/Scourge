import flash.display.BitmapData;
import flash.utils.ByteArray;
import flash.Memory;
import haxe.macro.Expr;

class Buffer {
	public var start(default,null):Int;
	public var end(default, null):Int;
	public var size(default,null):Int;
	function new (start:Int, end:Int) {
		this.start = start;
		this.end = end;
		this.size = end - start;
	}
	
	inline
	public function getI32 (addr:Int){
		#if debug
		Assert.bounds (start, end, addr, 4);
		#end
		return Memory.getI32 (addr);
	}
	
	inline
	public function setI32 (addr:Int, i:Int){
		#if debug
		Assert.bounds (start, end, addr, 4);
		#end
		Memory.setI32 (addr, i);
	}
	
	//#if !debug inline #end
	inline
	public function getByte (addr:Int){
		#if debug
		Assert.bounds (start, end, addr, 1);
		#end
		return Memory.getByte (addr);
	}
	
	inline
	public function setByte (addr:Int, b:Int){
		#if debug
		Assert.bounds (start, end, addr, 1);
		#end
		Memory.setByte (addr, b);
	}
	
	static var current_pos:Int;
	static var ba:ByteArray;
	public static function allocate (bytes:Int):Buffer {
		if (ba == null) {
			ba = new ByteArray( );
			ba.length = 10000000;
			Memory.select (ba);
		}
		
		var start = current_pos;
		var end = current_pos + bytes;
		current_pos += bytes;
		
		if (current_pos > Std.int(ba.length)) {
			ba.length += bytes + 100000;
		}
		
		return new Buffer (start, end);
	}
	
	public static function draw (bmd:BitmapData, buffer:Buffer)
	{
		var sz:Int = Std.int (bmd.width) * Std.int (bmd.height) * 4;
		Assert.equals (sz, buffer.size);
		
		ba.position = buffer.start;
		bmd.setPixels (bmd.rect, ba);
		ba.position = 0;
	}
	
	public static function fromBitmapAlpha (bmd:BitmapData, ?wid:Int = -1, ?hgt:Int = -1):Buffer
	{
		if (wid <= 0 || wid > bmd.width ) wid = Std.int (bmd.width );
		if (hgt <= 0 || hgt > bmd.height) hgt = Std.int (bmd.height);
		
		var buffer:Buffer = Buffer.allocate (wid * hgt);
		var addr:Int = buffer.start;
		
		for (y in 0...hgt)
		{
			for (x in 0...wid)
			{
				var val:UInt = bmd.getPixel32 (x, y);
				var alpha:Int = (val >>> 24);
				buffer.setByte (addr++, alpha);
			}
		}
		
		return buffer;
	}
	
	public static function fromBitmap (bmd:BitmapData, ?wid:Int = -1, ?hgt:Int = -1):Buffer
	{
		if (wid <= 0 || wid > bmd.width ) wid = Std.int (bmd.width );
		if (hgt <= 0 || hgt > bmd.height) hgt = Std.int (bmd.height);
		
		var buffer:Buffer = Buffer.allocate (wid * hgt * 4);
		var addr:Int = buffer.start;
		
		for (y in 0...hgt)
		{
			for (x in 0...wid)
			{
				var val:UInt = bmd.getPixel32 (x, y);
				
				var a:Int = (val >> 24) & 0xFF;
				var r:Int = (val >> 16) & 0xFF;
				var g:Int = (val >>  8) & 0xFF;
				var b:Int = (val >>  0) & 0xFF;
				
				buffer.setByte (addr++, a);
				buffer.setByte (addr++, r);
				buffer.setByte (addr++, g);
				buffer.setByte (addr++, b);
			}
		}
		
		return buffer;
	}
}