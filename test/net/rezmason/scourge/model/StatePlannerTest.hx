package net.rezmason.scourge.model;

import massive.munit.Assert;
import VisualAssert;

import net.rezmason.ropes.Aspect;
import net.rezmason.ropes.GridLocus;
import net.rezmason.ropes.RopesTypes;
import net.rezmason.ropes.Rule;
import net.rezmason.ropes.State;
import net.rezmason.ropes.StatePlanner;
import net.rezmason.scourge.model.aspects.TestAspect;
import net.rezmason.scourge.model.aspects.OwnershipAspect;
import net.rezmason.scourge.model.rules.BuildGlobalsRule;
import net.rezmason.scourge.model.rules.TestRule;

using net.rezmason.ropes.GridUtils;
using net.rezmason.ropes.StatePlan;
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
        var buildStateRule:BuildGlobalsRule = new BuildGlobalsRule();
        var testRule:TestRule = new TestRule();
        buildStateRule.init({firstPlayer:0});
        testRule.init(null);
        var rules:Array<Rule> = [null, buildStateRule, testRule];
        var state:State = new State(key);
        var plan:StatePlan = planner.planState(state, rules);
        for (rule in rules) if (rule != null) rule.prime(state,  plan,  history,  historyState);

        // Make sure there's the right aspects on the state

        var stateTestValue_:AspectPtr = plan.onState(TestAspect.VALUE_1);
        Assert.isNotNull(state.globals[stateTestValue_]);

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
