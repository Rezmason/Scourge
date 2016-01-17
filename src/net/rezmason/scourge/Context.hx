package net.rezmason.scourge;

import net.rezmason.hypertype.HypertypeContext;
import net.rezmason.hypertype.core.SceneGraph;
import net.rezmason.hypertype.core.Telemetry;
import net.rezmason.scourge.errands.BeginNavErrand;
import net.rezmason.utils.santa.Santa;
import net.rezmason.utils.santa.Present;

class Context {
    public function new():Void {
        Telemetry.init();
        new HypertypeContext();
        new GameContext();
        new BeginNavErrand().run();
        // makeMatrix();
    }

    function makeMatrix() {
        var demo = new net.rezmason.hypertype.demo.MatrixDemo();
        var scene = new net.rezmason.hypertype.core.Scene();
        scene.camera.scaleMode = net.rezmason.hypertype.core.CameraScaleMode.NO_BORDER;
        scene.root.addChild(demo.body);
        scene.focus = demo.body;
        var sceneGraph:SceneGraph = new Present(SceneGraph);
        sceneGraph.addScene(scene);
    }
}
