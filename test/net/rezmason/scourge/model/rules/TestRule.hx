package net.rezmason.scourge.model.rules;

import net.rezmason.ropes.RopesTypes;
import net.rezmason.ropes.Rule;
import net.rezmason.scourge.model.aspects.TestAspect;

class TestRule extends Rule {

    @extra(TestAspect.VALUE_1) var extraVal_:AspectPtr;
    @node(TestAspect.VALUE_1) var nodeVal_:AspectPtr;
    @player(TestAspect.VALUE_1) var playerVal_:AspectPtr;
    @state(TestAspect.VALUE_1) var stateVal_:AspectPtr;

    public function new():Void { super(); }
}

