package net.rezmason.scourge.model.rules;

import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.aspects.TestAspect;

class TestRule extends Rule {

    @extra(TestAspect.VALUE) var extraVal_:AspectPtr;
    @node(TestAspect.VALUE) var nodeVal_:AspectPtr;
    @player(TestAspect.VALUE) var playerVal_:AspectPtr;
    @state(TestAspect.VALUE) var stateVal_:AspectPtr;
}

