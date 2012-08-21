package net.rezmason.scourge.model.aspects;

import net.rezmason.scourge.model.ModelTypes;

class BodyAspect extends Aspect {

    public static var id(default, null):Int = Aspect.ids++;

    public var head:Int;

    public function new(history:History):Void {
        head = history.alloc(-1);
    }
}
