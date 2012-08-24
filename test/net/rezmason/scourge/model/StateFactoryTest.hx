package net.rezmason.scourge.model;

import massive.munit.Assert;

import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.GridNode;
import net.rezmason.scourge.model.Aspect;
import net.rezmason.scourge.model.aspects.TestAspect;
import net.rezmason.scourge.model.aspects.OwnershipAspect;
import net.rezmason.scourge.model.rules.TestRule;

using net.rezmason.scourge.model.GridUtils;

class StateFactoryTest {

    @Before
    public function setup():Void {

    }

    @After
    public function tearDown():Void {

    }

    @Test
    public function configTest1():Void {

        var history:StateHistory = new StateHistory();

        // make state config and generate state
        var factory:StateFactory = new StateFactory();
        var stateCfg:StateConfig = new StateConfig();
        stateCfg.rules = [null, new TestRule()];
        var state:State = factory.makeState(stateCfg, history);

        // Make sure there's the right aspects on the state

        var stateTestValue_:AspectPtr = state.stateAspectLookup[TestAspect.VALUE.id];
        Assert.areNotEqual(-1, stateTestValue_);
        Assert.isNotNull(history.get(state.aspects[stateTestValue_]));

        // Make sure there's the right aspects on each player
        var playerTestValue_:AspectPtr = state.playerAspectLookup[TestAspect.VALUE.id];
        Assert.areNotEqual(-1, playerTestValue_);
        for (ike in 0...state.players.length) {
            Assert.isNotNull(history.get(state.players[ike][playerTestValue_]));
        }

        // Make sure there's the right aspects on each node
        var nodeTestValue_:AspectPtr = state.nodeAspectLookup[TestAspect.VALUE.id];
        Assert.areNotEqual(-1, nodeTestValue_);

        for (node in state.nodes) {
            Assert.isNotNull(history.get(node.value[nodeTestValue_]));
        }
    }
}
