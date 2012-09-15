package net.rezmason.scourge.model;

import massive.munit.Assert;

import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.rules.BuildBoardRule;
import net.rezmason.scourge.model.rules.DraftPlayersRule;

using net.rezmason.scourge.model.GridUtils;
using net.rezmason.scourge.model.BoardUtils;
using net.rezmason.utils.Pointers;

class RuleTest
{
    var history:StateHistory;
    var time:Float;

    var state:State;

    public function new() {

    }

    @BeforeClass
    public function beforeClass():Void {
        history = new StateHistory();
    }

    @AfterClass
    public function afterClass():Void {
        history.wipe();
        history = null;
    }

    private function makeState(initGrid:String, numPlayers:Int, rules:Array<Rule>):State {

        history.wipe();

        // make player config and generate players
        var playerCfg:PlayerConfig = {numPlayers:numPlayers, history:history};
        var draftPlayersRule:DraftPlayersRule = new DraftPlayersRule(playerCfg);

        // make board config and generate board
        var boardCfg:BoardConfig = {circular:false, initGrid:initGrid, history:history};
        var buildBoardRule:BuildBoardRule = new BuildBoardRule(boardCfg);

        rules.unshift(buildBoardRule);
        rules.unshift(draftPlayersRule);

        return new StateFactory().makeState(rules, history);
    }

    private function testListLength(expectedLength:Int, first:BoardNode, next:AspectPtr, prev:AspectPtr):Int {
        var count:Int = 0;
        var last:BoardNode = null;

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
}
