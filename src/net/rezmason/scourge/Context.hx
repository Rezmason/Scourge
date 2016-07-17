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
        Telemetry.changeName('.init');
        new HypertypeContext();
        new GameContext();
        new BeginNavErrand().run();
        // makeMatrix();
        Telemetry.changeName('.lime');
    }

    function makeMatrix() {
        var demo = new net.rezmason.hypertype.demo.MatrixDemo();
        var sceneGraph:SceneGraph = new Present(SceneGraph);
        sceneGraph.root.addChild(demo.body);
    }
}
