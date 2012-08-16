package net.rezmason.scourge.model.aspects;

class OwnershipAspect extends Aspect {

    public static var id(default, null):Int = Aspect.ids++;

    public var isFilled:Int;
    public var occupier:Int;

    public function new(history:History<Int>):Void {
        isFilled = history.alloc(0);
        occupier = history.alloc(-1);
    }
}
