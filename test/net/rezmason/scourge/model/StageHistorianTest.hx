package net.rezmason.scourge.model;

import massive.munit.Assert;

import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.aspects.FreshnessAspect;
import net.rezmason.scourge.model.rules.BuildBoardRule;
import net.rezmason.scourge.model.rules.BuildPlayersRule;
import net.rezmason.scourge.model.rules.BuildStateRule;
import net.rezmason.scourge.model.rules.EatCellsRule;

using net.rezmason.scourge.model.BoardUtils;

class StageHistorianTest {

	var time:Float;

	@Before
    public function setup():Void {
        time = massive.munit.util.Timer.stamp();
    }

    @After
    public function tearDown():Void {
        time = massive.munit.util.Timer.stamp() - time;
        trace("tick " + time);
    }


	@Test
	public function transferAndCommitTest():Void {

		var history:StateHistory = new StateHistory();
		var historyState:State = new State();
		var state:State = new State();

		var config = {
			firstPlayer:0,
			numPlayers:2,
			circular:false,
			initGrid:TestBoards.twoPlayerGrab,

			history:history,
			historyState:historyState,

			recursive:false,
			eatHeads:true,
			takeBodiesFromHeads:false,
		}

        var buildStateRule:BuildStateRule = new BuildStateRule(cast config);
		var buildPlayersRule:BuildPlayersRule = new BuildPlayersRule(cast config);
        var buildBoardRule:BuildBoardRule = new BuildBoardRule(cast config);
        var eatRule:EatCellsRule = new EatCellsRule(cast config);

        var rules:Array<Rule> = [buildStateRule, buildPlayersRule, buildBoardRule, eatRule];
        var plan:StatePlan = new StatePlanner().planState(state, rules);

        var freshness_:AspectPtr = plan.nodeAspectLookup[FreshnessAspect.FRESHNESS.id];

		var historian:StateHistorian = new StateHistorian(state, historyState, history);

		var board0:String = state.spitBoard(plan);
		//trace(board0);
		var time0:Int = history.revision;

		// Freshen and eat body
		state.freshen(freshness_, 7, 7);
        state.freshen(freshness_, 9, 7);
        eatRule.chooseOption(0);

		var board1:String = state.spitBoard(plan);
		//trace(board1);
		historian.write();
		var time1:Int = history.commit();

		// Freshen and eat head
		state.freshen(freshness_, 12, 6);
		eatRule.chooseOption(0);

		var board2:String = state.spitBoard(plan);
		//trace(board2);
		historian.write();
		var time2:Int = history.commit();

		// No change!

		var board3:String = state.spitBoard(plan);
		//trace(board3);
		historian.write();
		var time3:Int = history.commit();

		historian.read();
		Assert.areEqual(board3, state.spitBoard(plan));

		history.revert(time2);
		historian.read();
		Assert.areEqual(board2, state.spitBoard(plan));

		history.revert(time1);
		historian.read();
		Assert.areEqual(board1, state.spitBoard(plan));

		history.revert(time0);
		historian.read();
		Assert.areEqual(board0, state.spitBoard(plan));
	}
}
