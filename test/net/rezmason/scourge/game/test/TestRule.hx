package net.rezmason.scourge.game.test;

import net.rezmason.praxis.PraxisTypes;
import net.rezmason.scourge.game.test.TestAspect;

class TestRule extends Rule {

    @extra(TestAspect.VALUE_1) var extraVal_:AspectPointer;
    @space(TestAspect.VALUE_1) var spaceVal_:AspectPointer;
    @player(TestAspect.VALUE_1) var playerVal_:AspectPointer;
    @global(TestAspect.VALUE_1) var stateVal_:AspectPointer;
}

