package net.rezmason.scourge.model.aspects;

class TestAspect extends Aspect {

    public static var id(default, null):Int = Aspect.ids++;

    public var value:Int;

    public function new():Void {
        value = 1;
    }
}
