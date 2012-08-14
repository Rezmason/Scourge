package net.rezmason.scourge.model.aspects;

class OwnershipAspect extends Aspect {

    public static var id(default, null):Int = Aspect.ids++;

    public var isFilled:Int;
    public var occupier:Int;

    public function new():Void {
        isFilled = 0;
        occupier = -1;
    }
}
