package net.rezmason.scourge.model.rules;

import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.aspects.TestAspect;

class TestRule extends Rule {

    public function new():Void {
        super();

        stateAspectRequirements.push(TestAspect.VALUE);
        playerAspectRequirements.push(TestAspect.VALUE);
        nodeAspectRequirements.push(TestAspect.VALUE);
    }
}

