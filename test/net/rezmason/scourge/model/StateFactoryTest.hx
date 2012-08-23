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

        var history:History<Int> = new History<Int>();

        // make state config and generate state
        var factory:StateFactory = new StateFactory();
        var stateCfg:StateConfig = new StateConfig();
        stateCfg.numPlayers = 2;
        stateCfg.rules = [null, new TestRule()];
        var state:State = factory.makeState(stateCfg, history);

        Assert.areEqual(stateCfg.numPlayers, state.players.length);

        // Make sure there's the right aspects on the state

        var stateTestValue_:Int = state.stateAspectLookup[TestAspect.VALUE.id];
        Assert.areNotEqual(-1, stateTestValue_);
        Assert.isNotNull(history.get(state.aspects[stateTestValue_]));

        // Make sure there's the right aspects on each player
        var playerTestValue_:Int = state.playerAspectLookup[TestAspect.VALUE.id];
        Assert.areNotEqual(-1, playerTestValue_);
        for (ike in 0...state.players.length) {
            Assert.isNotNull(history.get(state.players[ike][playerTestValue_]));
        }

        // Make sure there's the right aspects on each node
        var nodeTestValue_:Int = state.nodeAspectLookup[TestAspect.VALUE.id];
        Assert.areNotEqual(-1, nodeTestValue_);

        for (node in state.nodes) {
            Assert.isNotNull(history.get(node.value[nodeTestValue_]));
        }
    }
}
