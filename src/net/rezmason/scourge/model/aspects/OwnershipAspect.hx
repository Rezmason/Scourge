package net.rezmason.scourge.model.aspects;

import net.rezmason.scourge.model.ModelTypes;

class OwnershipAspect extends Aspect {

    public static var id(default, null):Int = Aspect.ids++;

    public var isFilled:Int;
    public var occupier:Int;

    public function new(allocator:HistoryAllocator):Void {
        isFilled = allocator(0);
        occupier = allocator(-1);
    }
}
