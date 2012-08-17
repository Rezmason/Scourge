package net.rezmason.scourge.model.rules;

import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.aspects.TestAspect;

class TestRule extends Rule {

    var reqs:AspectRequirements;

    public function new(historyArray:Array<Int>):Void {
        super(historyArray);
        reqs = new AspectRequirements();
        reqs.set(TestAspect.id, TestAspect);
    }

    override public function listStateAspectRequirements():AspectRequirements { return reqs; }
    override public function listPlayerAspectRequirements():AspectRequirements { return reqs; }
    override public function listBoardAspectRequirements():AspectRequirements { return reqs; }
}

