package net.rezmason.scourge;

import net.rezmason.hypertype.HypertypeContext;
import net.rezmason.hypertype.core.Telemetry;
import net.rezmason.scourge.errands.BeginNavErrand;

class Context {
    public function new():Void {
        Telemetry.init();
        Telemetry.changeName('.init');
        new HypertypeContext();
        new GameContext();
        new BeginNavErrand().run();
        Telemetry.changeName('.lime');
    }
}
