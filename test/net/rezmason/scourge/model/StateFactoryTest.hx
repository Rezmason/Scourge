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
        var testAspect:Aspect = state.aspects.get(TestAspect.id);
        Assert.isNotNull(testAspect);
        Assert.isTrue(Std.is(testAspect, TestAspect));
        Assert.isNotNull(history.get(cast(testAspect, TestAspect).value));

        // Make sure there's the right aspects on each player
        for (ike in 0...state.players.length) {
            var player:Aspects = state.players[ike];
            testAspect = player.get(TestAspect.id);
            Assert.isNotNull(testAspect);
            Assert.isTrue(Std.is(testAspect, TestAspect));
            Assert.isNotNull(history.get(cast(testAspect, TestAspect).value));
        }

        // There's no nodes yet

        // TODO: Test aspect template for state, player and node
    }
}
