package net.rezmason.scourge.textview.waves;

using Lambda;

class WavePool {

    var ripples:Array<Ripple>;
    var heights:Array<Float>;
    public var size(default, set):Int;

    public function new(size:Int):Void {
        ripples = [];
        heights = [];
        this.size = size;
    }

    public function addRipple(ripple:Ripple):Void {
        if (!ripples.has(ripple)) ripples.push(ripple);
        ripple.init();
    }

    public function removeRipple(ripple:Ripple):Void ripples.remove(ripple);

    public function update(delta:Float):Void {

        if (delta != 0) for (ripple in ripples) ripple.update(delta, size);

        for (ike in 0...size) {
            var y:Float = 0;
            for (ripple in ripples) y += ripple.apply(ike);
            heights[ike] = y;
        }
    }

    public inline function getHeightAtIndex(index:Int):Float {
        return (index < 0 || index >= size) ? Math.NaN : heights[index];
    }

    public function set_size(val:Int):Int {
        if (val < 0) val = 0;
        this.size = val;
        update(0);
        return val;
    }
}

