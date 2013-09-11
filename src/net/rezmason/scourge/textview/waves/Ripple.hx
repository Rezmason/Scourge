package net.rezmason.scourge.textview.waves;

class Ripple {
    public var func:Float->Float;
    public var mag:Float;
    public var dMag:Float;
    public var x:Float;
    public var p:Float;
    public var a:Float;
    public var dX:Float;

    public function new(func:Float->Float, a:Float, p:Float, dMag:Float, dX:Float):Void {
        this.func = func;
        this.a = a;
        this.p = p;
        this.dMag = dMag;
        this.dX = dX;
    }

    public inline function init():Void {
        x = -p;
        mag = a;
    }

    public inline function update(delta:Float, poolSize:Float):Void {
        x += dX * delta;

        mag = mag * (1 + delta * (dMag - 1));

        if (x > poolSize + p || mag < 0.05) {
            x = -p;
            mag = a;
        }
    }

    public inline function apply(x:Float):Float {
        x = (x - this.x) / p;
        return (x <= -1 || x >= 1) ? 0 : func(x) * mag;
    }
}
