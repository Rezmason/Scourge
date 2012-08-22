package net.rezmason.scourge.model.rules;

import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.aspects.TestAspect;

class TestRule extends Rule {

    static var reqs:AspectRequirements;

    public function new():Void {
        super();

        if (reqs == null) reqs = [
            TestAspect.VALUE,
        ];
    }

    override public function listStateAspectRequirements():AspectRequirements { return reqs; }
    override public function listPlayerAspectRequirements():AspectRequirements { return reqs; }
    override public function listBoardAspectRequirements():AspectRequirements { return reqs; }
}

