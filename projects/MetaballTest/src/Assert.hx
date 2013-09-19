class Assert
{
	public static inline function bounds (start:Int, end:Int, addr:Int, bytes:Int) {
		if ( addr < start ) throw "OOB: Left " + start + "->" + end + " : " + addr;
		if ( addr + bytes > end ) throw "OOB: Right " + start + "->" + end + " : " + addr;
	}
	
	public static inline function equals (a:Dynamic, b:Dynamic) {
		if (a != b) throw a + " does not equal " + b;
	}
}
