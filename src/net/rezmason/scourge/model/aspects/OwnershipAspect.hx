package net.rezmason.scourge.model.aspects;

class OwnershipAspect extends Aspect {

    public static var id(default, null):Int = Aspect.ids++;

    public var isFilled(default, null):Pointer<Int>;
    public var occupier(default, null):Pointer<Int>;

    public function new():Void {
        isFilled = new Pointer<Int>();
        occupier = new Pointer<Int>();

        isFilled.value = 0;
        occupier.value = -1;
    }
}
