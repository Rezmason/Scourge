package net.rezmason.scourge.waves;

import flash.display.Shape;
import flash.events.Event;
import haxe.Timer;

class WavePoolShape extends Shape {

    public var pool(default, null):WavePool;
    public var size(default, null):Int;

    var then:Float;

    public function new(size:Int):Void {
        super();
        pool = new WavePool(size);
        this.size = size;
        addEventListener(Event.ENTER_FRAME, update);
        then = Timer.stamp();
    }

    function update(event:Event):Void {
        var now:Float = Timer.stamp();
        pool.update(now - then);
        then = now;

        this.graphics.clear();
        this.graphics.lineStyle(2, 0xFFFFFF);
        this.graphics.moveTo(0, pool.getHeightAtIndex(0));
        for (ike in 1...size) this.graphics.lineTo(ike, pool.getHeightAtIndex(ike));
        this.graphics.lineTo(size, 0);
    }
}

