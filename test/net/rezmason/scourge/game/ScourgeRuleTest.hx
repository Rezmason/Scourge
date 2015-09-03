package net.rezmason.scourge.game;

import massive.munit.Assert;
import VisualAssert;

import net.rezmason.praxis.PraxisTypes;
import net.rezmason.praxis.state.State;
import net.rezmason.praxis.state.StatePlan;
import net.rezmason.praxis.state.StatePlanner;
import net.rezmason.praxis.state.StateHistorian;
import net.rezmason.scourge.game.build.BuildBoardRule;
import net.rezmason.scourge.game.build.BuildGlobalRule;
import net.rezmason.scourge.game.build.BuildPlayersRule;
import net.rezmason.scourge.game.build.PetriBoardFactory;

using net.rezmason.praxis.aspect.AspectUtils;
using net.rezmason.grid.GridUtils;
using net.rezmason.utils.pointers.Pointers;

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

    private function makeState(rules:Array<Rule> = null, numPlayers:Int = 1, initGrid:String = null, circular:Bool = false):Void {

        history.wipe();
        historyState.wipe();
        state.wipe();

        if (rules == null) rules = [];

        // make state config and generate state
        var buildStateRule:BuildGlobalRule = new BuildGlobalRule({firstPlayer:0});

        // make player config and generate players
        var buildPlayersRule:BuildPlayersRule = new BuildPlayersRule({numPlayers:numPlayers});

        // make board config and generate board
        var boardParams = {numPlayers:numPlayers, cells:PetriBoardFactory.create(numPlayers, circular, initGrid)};
        var buildBoardRule:BuildBoardRule = new BuildBoardRule(boardParams);

        rules.unshift(buildBoardRule);
        rules.unshift(buildPlayersRule);
        rules.unshift(buildStateRule);

        plan = new StatePlanner().planState(state, rules);
        for (rule in rules) rule.prime(state, plan, history, historyState);
    }

    private function testListLength(expectedLength:Int, first:AspectSet, next:AspectPtr, prev:AspectPtr):Int {
        var count:Int = 0;
        var last:AspectSet = null;

        for (space in first.iterate(state.spaces, next)) {
            count++;
            last = space;
            if (count > expectedLength) break;
        }
        if (expectedLength != count) return expectedLength - count;

        count = 0;
        for (space in last.iterate(state.spaces, prev)) {
            count++;
            if (count > expectedLength) break;
        }

        return expectedLength - count;
    }

    private function getID(aspectSet:AspectSet):Int {
        return aspectSet[identPtr];
    }
}
