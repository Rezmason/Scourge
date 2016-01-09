package net.rezmason.scourge;

import net.rezmason.scourge.errands.BeginNavErrand;
import net.rezmason.hypertype.core.Telemetry;
import net.rezmason.hypertype.HypertypeContext;
import net.rezmason.utils.santa.Santa;

class Context {
    public function new():Void {
        Telemetry.init();
        new HypertypeContext();
        new GameContext();
        new BeginNavErrand().run();
        // makeMatrix(engine);
    }

    function makeMatrix(engine) {
        var demo = new net.rezmason.hypertype.demo.MatrixDemo();
        var scene = new net.rezmason.hypertype.core.Scene();
        scene.camera.scaleMode = net.rezmason.hypertype.core.CameraScaleMode.NO_BORDER;
        scene.root.addChild(demo.body);
        scene.focus = demo.body;
        engine.addScene(scene);
    }
}
