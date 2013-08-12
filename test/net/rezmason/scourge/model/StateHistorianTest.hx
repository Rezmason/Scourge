package net.rezmason.scourge.model;

import massive.munit.Assert;
import VisualAssert;

import net.rezmason.ropes.Types;
import net.rezmason.ropes.State;
import net.rezmason.ropes.StateHistorian;
import net.rezmason.ropes.StatePlanner;
import net.rezmason.ropes.Rule;
import net.rezmason.scourge.model.aspects.FreshnessAspect;
import net.rezmason.scourge.model.rules.BuildBoardRule;
import net.rezmason.scourge.model.rules.BuildPlayersRule;
import net.rezmason.scourge.model.rules.BuildStateRule;
import net.rezmason.scourge.model.rules.EatCellsRule;
import net.rezmason.scourge.model.rules.PickPieceRule;
import net.rezmason.scourge.tools.Resource;

using net.rezmason.utils.Pointers;
using net.rezmason.scourge.model.BoardUtils;
using net.rezmason.ropes.StatePlan;

class StateHistorianTest {

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
	public function transferAndCommitTest():Void {

		var historian:StateHistorian = new StateHistorian();

		var history:StateHistory = historian.history;
		var historyState:State = historian.historyState;
		var state:State = historian.state;

		var config = {
			firstPlayer:0,
			numPlayers:2,
			circular:false,
			initGrid:TestBoards.twoPlayerGrab,

            buildCfg: { history:history, historyState:historyState },

			recursive:false,
			eatHeads:true,
			takeBodiesFromHeads:false,

            pieceTableIDs:[0, 1, 2, 3, 4],
            allowFlipping:true,
            allowRotating:true,
            allowAll:false,
            hatSize:1,
            randomFunction:function() return 0,
            pieces:new Pieces(Resource.getString('tables/pieces.json.txt'))
		}

        var buildStateRule:BuildStateRule = new BuildStateRule(cast config);
		var buildPlayersRule:BuildPlayersRule = new BuildPlayersRule(cast config);
        var buildBoardRule:BuildBoardRule = new BuildBoardRule(cast config);
        var eatRule:EatCellsRule = new EatCellsRule(cast config);
        var pickPieceRule:PickPieceRule = new PickPieceRule(cast config);

        var rules:Array<Rule> = [buildStateRule, buildPlayersRule, buildBoardRule, eatRule, pickPieceRule];
        var plan:StatePlan = new StatePlanner().planState(state, rules);

        for (rule in rules) rule.prime(state, plan);

        var freshness_:AspectPtr = plan.onNode(FreshnessAspect.FRESHNESS);


        var boards:Array<String> = [];
        var times:Array<Int> = [];
        var extras:Array<String> = [];

        function pushChange():Void {
            boards.push(state.spitBoard(plan));
            extras.push(Std.string(state.extras));
            historian.write();
            times.push(history.commit());
        }

		pushChange();

        // Pick a few pieces
        for (ike in 0...10) {
            pickPieceRule.update();
            pickPieceRule.chooseMove();
        }

		// Freshen and eat body

        state.grabXY(7, 7).value[freshness_] = 1;
        state.grabXY(9, 7).value[freshness_] = 1;
        eatRule.chooseMove();

		pushChange();

		// Freshen and eat head
        state.grabXY(12, 6).value[freshness_] = 1;
		eatRule.chooseMove();

		pushChange();

		// No change!

		pushChange();

        while (times.length > 0) {
            history.revert(times.pop());
            historian.read();
            Assert.areEqual(boards.pop(), state.spitBoard(plan));
            Assert.areEqual(extras.pop(), Std.string(state.extras));
        }
	}
}
