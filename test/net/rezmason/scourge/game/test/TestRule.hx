package net.rezmason.scourge.game.test;

import net.rezmason.praxis.PraxisTypes;
import net.rezmason.scourge.game.test.TestAspect;

class TestRule extends Rule {

    @extra(TestAspect.VALUE_1) var extraVal_:AspectPtr;
    @space(TestAspect.VALUE_1) var spaceVal_:AspectPtr;
    @player(TestAspect.VALUE_1) var playerVal_:AspectPtr;
    @global(TestAspect.VALUE_1) var stateVal_:AspectPtr;
}

