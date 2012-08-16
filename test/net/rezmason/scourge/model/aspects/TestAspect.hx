package net.rezmason.scourge.model.aspects;

class TestAspect extends Aspect {

    public static var id(default, null):Int = Aspect.ids++;

    public var value:Int;

    public function new(history:History<Int>):Void {
        value = history.alloc(1);
    }
}
