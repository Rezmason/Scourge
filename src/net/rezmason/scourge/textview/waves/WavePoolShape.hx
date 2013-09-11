package net.rezmason.scourge.textview.waves;

import flash.display.Shape;

class WavePoolShape extends Shape {

    public var pool(default, null):WavePool;
    public var size(default, null):Int;

    public function new(size:Int):Void {
        super();
        pool = new WavePool(size);
        this.size = size;
        addEventListener("enterFrame", function(e) update(0.05));
    }

    public function update(delta:Float):Void {
        pool.update(delta);

        this.graphics.clear();
        this.graphics.beginFill(0xFFFFFF);
        this.graphics.moveTo(0, 0);
        for (ike in 0...size) this.graphics.lineTo(ike, pool.heightAtIndex(ike));
        this.graphics.lineTo(size, 0);
    }
}

