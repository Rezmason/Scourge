package net.rezmason.scourge.model;

import massive.munit.Assert;

import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.rules.BuildBoardRule;
import net.rezmason.scourge.model.rules.DraftPlayersRule;

using net.rezmason.scourge.model.GridUtils;
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
        var playerCfg:PlayerConfig = {numPlayers:numPlayers};
        var draftPlayersRule:DraftPlayersRule = new DraftPlayersRule(playerCfg);

        // make board config and generate board
        var boardCfg:BoardConfig = {circular:false, initGrid:initGrid};
        var buildBoardRule:BuildBoardRule = new BuildBoardRule(boardCfg);

        rules.unshift(buildBoardRule);
        rules.unshift(draftPlayersRule);

        return new StateFactory().makeState(rules, history);
    }
}
