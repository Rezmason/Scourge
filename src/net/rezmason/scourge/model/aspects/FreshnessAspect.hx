package net.rezmason.scourge.model.aspects;

import net.rezmason.scourge.model.ModelTypes;

class FreshnessAspect extends Aspect {

    public static var id(default, null):Int = Aspect.ids++;

    public var freshness:Int;

    public function new(history:History<Int>):Void {
        freshness = history.alloc(0);
    }
}
