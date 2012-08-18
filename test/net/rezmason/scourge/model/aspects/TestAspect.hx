package net.rezmason.scourge.model.aspects;

import net.rezmason.scourge.model.ModelTypes;

class TestAspect extends Aspect {

    public static var id(default, null):Int = Aspect.ids++;

    public var value:Int;

    public function new(allocator:HistoryAllocator):Void {
        value = allocator(1);
    }
}
