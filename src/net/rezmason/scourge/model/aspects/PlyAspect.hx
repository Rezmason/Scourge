package net.rezmason.scourge.model.aspects;

import net.rezmason.scourge.model.ModelTypes;

class PlyAspect extends Aspect {

    public static var id(default, null):Int = Aspect.ids++;

    public var currentPlayer:Int;

    public function new(allocator:HistoryAllocator):Void {
        currentPlayer = allocator(0);
    }
}
