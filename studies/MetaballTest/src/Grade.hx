typedef GradientEntry = {
	var ratio:Float;
	var value:Float;
	var duplicate:Bool;
}


class Grade {
	
	public static function generateLookupTable(set:Array<GradientEntry>, ?domain:Int = 0xFF, ?range:Int = 0xFF, ?size:Int = -1):Buffer {
		
		if (domain < 2) domain = 2;
		if (size < domain) size = domain;
		
		if (set.length == 0) throw "Grade: Empty sets are invalid.";
		for (entry in set) validateEntry(entry);
		if (set.length == 1) {
			set.push({
				ratio: (set[0].ratio == 1. ? 0. : 1.), 
				value:set[0].value, 
				duplicate:false
			});
		}
		set.sort(entryComparator);
		
		var gradient:Array<Int> = [];
		var i:Int = 0;
		var gradItr:Int = 0;
		var m:Float;
		m = (set[i + 1].value - set[i].value) / (set[i + 1].ratio - set[i].ratio);
		var b:Float = set[i].value - m * set[i].ratio;
		while (i < set.length - 1) {
			
			if (set[i].duplicate) {
				i++;
				continue;
			}
			
			var _x:Float = gradItr / domain;
			
			if (_x >= set[i + 1].ratio) {
				i++;
				if (i >= set.length - 1) break;
				m = (set[i + 1].value - set[i].value) / (set[i + 1].ratio - set[i].ratio);
				b = set[i].value - m * set[i].ratio;
			}
			
			gradient[gradItr] = Std.int((m * _x + b) * range);
			gradItr++;
		}
		
		var buffer:Buffer = Buffer.allocate(size);
		
		for ( i in 0...domain) buffer.setByte (buffer.start + i, gradient[i]);
		for ( i in domain...size) buffer.setByte (buffer.start + i, 0xFF);
		
		return buffer;
	}
	
	private static function validateEntry(entry:GradientEntry):Void {
		if (Math.isNaN(entry.ratio) || entry.ratio < 0) entry.ratio = 0;
		if (entry.ratio > 1) entry.ratio = 1;
		
		if (Math.isNaN(entry.value) || entry.value < 0) entry.value = 0;
		if (entry.value > 1) entry.value = 1;
		
		entry.duplicate = false;
	}
	
	private static function entryComparator(e1:GradientEntry, e2:GradientEntry):Int
	{
		if (e1.duplicate) return 1;
		if (e2.duplicate) return -1;
		if (e1.ratio == e2.ratio) {
			if (e1.value < e2.value) {
				e2.duplicate = true;
				return -1;
			} else {
				e1.duplicate = true;
				return  1;
			}
		} else if (e1.ratio < e2.ratio) {
			return -1;
		}
		return 1;
	}
}
