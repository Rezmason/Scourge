package net.rezmason.scourge.model.aspects;

import net.rezmason.scourge.model.ModelTypes;

class PlyAspect extends Aspect {

    public static var id(default, null):Int = Aspect.ids++;

    public var currentPlayer:Int;

    public function new(history:History<Int>):Void {
        currentPlayer = history.alloc(0);
    }
}
