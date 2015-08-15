package net.rezmason.scourge.game;

import massive.munit.Assert;
import VisualAssert;

import net.rezmason.praxis.aspect.Aspect;
import net.rezmason.grid.Cell;
import net.rezmason.praxis.PraxisTypes;
import net.rezmason.praxis.state.State;
import net.rezmason.praxis.state.StatePlanner;
import net.rezmason.scourge.game.test.TestAspect;
import net.rezmason.scourge.game.body.OwnershipAspect;
import net.rezmason.scourge.game.build.BuildGlobalRule;
import net.rezmason.scourge.game.test.TestRule;

using net.rezmason.grid.GridUtils;
using net.rezmason.praxis.state.StatePlan;
using net.rezmason.utils.Pointers;

class StatePlannerTest {

    #if TIME_TESTS
    var time:Float;

    @Before
    public function setup():Void {
        time = massive.munit.util.Timer.stamp();
    }

    @After
    public function tearDown():Void {
        time = massive.munit.util.Timer.stamp() - time;
        trace('tick $time');
    }
    #end

    @Test
    public function configTest1():Void {

        var key:PtrKey = new PtrKey();

        var history:StateHistory = new StateHistory();
        var historyState:State = new State(key);
        // make state config and generate state
        var planner:StatePlanner = new StatePlanner();
        var buildStateRule:BuildGlobalRule = new BuildGlobalRule({firstPlayer:0});
        var testRule:TestRule = new TestRule(null);
        var rules:Array<Rule> = [null, buildStateRule, testRule];
        var state:State = new State(key);
        var plan:StatePlan = planner.planState(state, rules);
        for (rule in rules) if (rule != null) rule.prime(state,  plan,  history,  historyState);

        // Make sure there's the right aspects on the state

        var stateTestValue_:AspectPtr = plan.onGlobal(TestAspect.VALUE_1);
        Assert.isNotNull(state.global[stateTestValue_]);

        // Make sure there's the right aspects on each player
        var playerTestValue_:AspectPtr = plan.onPlayer(TestAspect.VALUE_1);
        for (ike in 0...state.players.length) {
            Assert.isNotNull(state.players[ike][playerTestValue_]);
        }

        // Make sure there's the right aspects on each node
        var nodeTestValue_:AspectPtr = plan.onNode(TestAspect.VALUE_1);
        for (node in state.nodes) Assert.isNotNull(node[nodeTestValue_]);
    }
}
