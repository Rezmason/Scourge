import flash.display.BitmapData;
import flash.display.Shape;
import flash.events.Event;

class CombinedBuffer extends Shape {
	
	public var output(default, null):BitmapData;
	public var frameBuffer(default, null):Buffer;
	private var input:Array<Buffer>;
	private static var byteLookup:Array<Int>;
	
	public function new(width:Int, height:Int, input_:Array<Buffer>):Void {
		super();
		
		frameBuffer = Buffer.allocate(width * height * 4);
		
		output = new BitmapData(width, height, true, 0x0);
		
		graphics.beginBitmapFill(output, null, false, true);
		graphics.drawRect(0, 0, width, height);
		graphics.endFill();
		
		input = input_;
		
		if (byteLookup == null) {
			byteLookup = [];
			for (i in 0...0xFF) {
				byteLookup.push(i);
			}
			
			for (i in 0...0xFF) {
				byteLookup.push(0xFF);
			}
		}
		
		addEventListener(Event.ADDED, update);
	}
	
	public function update(?event:Event):Void {
		clearBuffer(frameBuffer, 0x00FF00FF); // BGRA
		for (buffer in input) add(buffer, frameBuffer);
		if (stage != null) Buffer.draw (output, frameBuffer);
	}
	
	public static function add(src:Buffer, dst:Buffer):Void {
		
		#if debug
		
		Assert.equals(src.size, dst.size);
		
		#end
		
		var src_addr:Int = src.start;
		var end_addr:Int = src.end;
		var dst_addr:Int = dst.start;
		var lookup:Array<Int> = byteLookup;
		
		while ( src_addr < end_addr )
		{
			var spv:Int = src.getByte(src_addr);
			var dpv:Int = dst.getByte(dst_addr);
			
			var comb:Int = lookup[spv + dpv];
			
			dst.setByte(dst_addr, comb);
			
			src_addr++;
			dst_addr++;
		}
	}
	
	public static function clearBuffer (buffer:Buffer, color:UInt) {
		var addr:Int = buffer.start;
		var eaddr:Int = buffer.end;
		
		while (addr < eaddr) {
			buffer.setI32 (addr, color);
			
			addr += 4;
		}
	}
}
