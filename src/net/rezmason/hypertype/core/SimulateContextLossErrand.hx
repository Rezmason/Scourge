package net.rezmason.hypertype.core;

import haxe.Timer;
import net.rezmason.gl.GLSystem;
import net.rezmason.utils.Errand;
import net.rezmason.utils.santa.Present;

class SimulateContextLossErrand extends Errand<Void->Void> {
    
    var glSys:GLSystem;
    public function new() glSys = new Present(GLSystem);

    override public function run() {
        if (!glSys.connected) onComplete.dispatch();
        glSys.disconnect();
        Timer.delay(reconnect, 1000);
    }

    function reconnect() {
        glSys.connect();
        onComplete.dispatch();
    }
}
