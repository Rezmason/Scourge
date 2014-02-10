package net.rezmason.scourge.textview.waves;

import flash.display.Sprite;

class WaveDemo {
    public function new(scene:Sprite):Void {
        var container:Sprite = new Sprite();

        var w:Int = Std.int(scene.stage.stageWidth );
        var h:Int = Std.int(scene.stage.stageHeight);


        var wavePoolShape:WavePoolShape = new WavePoolShape(w + 1);

        var bolus = WaveFunctions.bolus;
        var heartbeat = WaveFunctions.heartbeat;

        // bolus = WaveFunctions.photocopy(bolus, 10);
        // heartbeat = WaveFunctions.photocopy(heartbeat, 10);

        wavePoolShape.pool.addRipple(new Ripple(bolus,     200, 200, 0.95, 300));
        wavePoolShape.pool.addRipple(new Ripple(bolus,     100, 100, 0.99, 060));
        wavePoolShape.pool.addRipple(new Ripple(heartbeat, 100, 150, 0.99, 150));

        container.y = h / 2;
        container.addChild(wavePoolShape);
        scene.addChild(container);
    }
}
