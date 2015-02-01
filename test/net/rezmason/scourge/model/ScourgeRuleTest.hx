package net.rezmason.scourge.model;

import massive.munit.Assert;
import VisualAssert;

import net.rezmason.ropes.RopesTypes;
import net.rezmason.ropes.State;
import net.rezmason.ropes.StatePlan;
import net.rezmason.ropes.StatePlanner;
import net.rezmason.ropes.StateHistorian;
import net.rezmason.scourge.model.rules.BuildBoardRule;
import net.rezmason.scourge.model.rules.BuildGlobalRule;
import net.rezmason.scourge.model.rules.BuildPlayersRule;

using net.rezmason.ropes.AspectUtils;
using net.rezmason.ropes.GridUtils;
using net.rezmason.utils.Pointers;

class ScourgeRuleTest
{
    var stateHistorian:StateHistorian;
    var history:StateHistory;
    var state:State;
    var historyState:State;
    var plan:StatePlan;
    var identPtr:AspectPtr;

    public function new() {

    }

    @BeforeClass
    public function beforeClass():Void {
        stateHistorian = new StateHistorian();
        history = stateHistorian.history;
        state = stateHistorian.state;
        historyState = stateHistorian.historyState;
        identPtr = Ptr.intToPointer(0, state.key);
    }

    @AfterClass
    public function afterClass():Void {
        stateHistorian.reset();

        stateHistorian = null;
        history = null;
        historyState = null;
        state = null;
        plan = null;
    }

    private function makeState(rules:Array<Rule> = null,  numPlayers:Int = 1, initGrid:String = null, circular:Bool = false):Void {

        history.wipe();
        historyState.wipe();
        state.wipe();

        if (rules == null) rules = [];

        // make state config and generate state
        var buildStateRule:BuildGlobalRule = new BuildGlobalRule();
        buildStateRule.init({firstPlayer:0});

        // make player config and generate players
        var buildPlayersRule:BuildPlayersRule = new BuildPlayersRule();
        buildPlayersRule.init({numPlayers:numPlayers});

        // make board config and generate board
        var buildBoardRule:BuildBoardRule = new BuildBoardRule();
        buildBoardRule.init({circular:circular, initGrid:initGrid});

        rules.unshift(buildBoardRule);
        rules.unshift(buildPlayersRule);
        rules.unshift(buildStateRule);

        plan = new StatePlanner().planState(state, rules);
        for (rule in rules) rule.prime(state, plan, history, historyState);
    }

    private function testListLength(expectedLength:Int, first:AspectSet, next:AspectPtr, prev:AspectPtr):Int {
        var count:Int = 0;
        var last:AspectSet = null;

        for (node in first.iterate(state.nodes, next)) {
            count++;
            last = node;
            if (count > expectedLength) break;
        }
        if (expectedLength != count) return expectedLength - count;

        count = 0;
        for (node in last.iterate(state.nodes, prev)) {
            count++;
            if (count > expectedLength) break;
        }

        return expectedLength - count;
    }

    private function getID(aspectSet:AspectSet):Int {
        return aspectSet[identPtr];
    }
}
