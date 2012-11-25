package net.rezmason.scourge.model;

import massive.munit.Assert;
import massive.munit.async.AsyncFactory;
import massive.munit.util.Timer;
import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.ScourgeConfigMaker;
import net.rezmason.scourge.model.aspects.BodyAspect;
import net.rezmason.scourge.model.aspects.PlyAspect;
import net.rezmason.scourge.model.aspects.WinAspect;

using net.rezmason.scourge.model.BoardUtils;
using net.rezmason.utils.Pointers;

class GameTest
{
	var stateHistorian:StateHistorian;
    var history:StateHistory;
    var state:State;
    var historyState:State;
    var plan:StatePlan;
    var configMaker:ScourgeConfigMaker;
    var basicRules:Hash<Rule>;
    var combinedRules:Hash<Rule>;

	public function new() {

	}

	@BeforeClass
	public function beforeClass():Void {
		configMaker = new ScourgeConfigMaker();
		stateHistorian = new StateHistorian();

        history = stateHistorian.history;
        state = stateHistorian.state;
        historyState = stateHistorian.historyState;
	}

	@AfterClass
	public function afterClass():Void {
		stateHistorian.reset();
		configMaker.reset();

		basicRules = null;
		combinedRules = null;
		configMaker = null;
		stateHistorian = null;
		history = null;
        historyState = null;
        state = null;
        plan = null;
	}

	@Before
	public function setup():Void {
		configMaker.reset();
		stateHistorian.reset();

		basicRules = null;
		combinedRules = null;
	}

	@Test
	public function allActionsRegisteredTest():Void {
		makeState();
		for (action in ScourgeConfigMaker.actionList) Assert.isNotNull(combinedRules.get(action));
	}

	@Test
	public function startActionTest():Void {
		// decay, cavity, killHeadlessPlayer, oneLivingPlayer, pickPiece

		configMaker.numPlayers = 2;
		configMaker.initGrid = TestBoards.twoPlayerBullshit;
		makeState();

		//trace(state.spitBoard(plan));
		var num0Cells:Int = ~/([^0])/g.replace(state.spitBoard(plan, false), "").length;
		var num1Cells:Int = ~/([^1])/g.replace(state.spitBoard(plan, false), "").length;

		Assert.areEqual(24, num0Cells);
		Assert.areEqual(32, num1Cells);

		combinedRules.get("startAction").update();
		combinedRules.get("startAction").chooseOption();

		//trace(state.spitBoard(plan));
		var num0Cells:Int = ~/([^0])/g.replace(state.spitBoard(plan, false), "").length;
		var num1Cells:Int = ~/([^1])/g.replace(state.spitBoard(plan, false), "").length;

		Assert.areEqual(20, num0Cells);
		Assert.areEqual(0, num1Cells);

		var totalArea_:AspectPtr = plan.playerAspectLookup[BodyAspect.TOTAL_AREA.id];
		var head_:AspectPtr = plan.playerAspectLookup[BodyAspect.HEAD.id];

		var winner_:AspectPtr = plan.stateAspectLookup[WinAspect.WINNER.id];
		var currentPlayer_:AspectPtr = plan.stateAspectLookup[PlyAspect.CURRENT_PLAYER.id];

		Assert.areEqual(36, state.players[0].at(totalArea_));
		Assert.areEqual(Aspect.NULL, state.players[1].at(head_));
		Assert.areEqual(0, state.aspects.at(winner_));
		Assert.areEqual(0, state.aspects.at(currentPlayer_));
	}

	@Test
	public function biteActionTest():Void {
		// bite, decay, cavity, killHeadlessPlayer, oneLivingPlayer

		configMaker.numPlayers = 2;
		configMaker.startingBites = 5;
		configMaker.initGrid = TestBoards.twoPlayerGrab;
		makeState();

		var winner_:AspectPtr = plan.stateAspectLookup[WinAspect.WINNER.id];
		var totalArea_:AspectPtr = plan.playerAspectLookup[BodyAspect.TOTAL_AREA.id];
		var currentPlayer_:AspectPtr = plan.stateAspectLookup[PlyAspect.CURRENT_PLAYER.id];

		combinedRules.get("startAction").update();
		combinedRules.get("startAction").chooseOption();

		var biteAction:Rule = combinedRules.get("biteAction");
		var dropAction:Rule = combinedRules.get("dropAction");

		Assert.areEqual(13, state.players[1].at(totalArea_));
		//trace(state.spitBoard(plan));
		//trace(state.aspects.at(currentPlayer_));

		biteAction.update();
		biteAction.chooseOption(4); // bite

		Assert.areEqual(6, state.players[1].at(totalArea_));
		//trace(state.spitBoard(plan));
		//trace(state.aspects.at(currentPlayer_));

		// How about some skipping?
		dropAction.update();
		dropAction.chooseOption(); // skip
		dropAction.update();
		dropAction.chooseOption(); // skip

		biteAction.update();
		biteAction.chooseOption(); // bite head

		Assert.areEqual(0, state.players[1].at(totalArea_));
		//trace(state.spitBoard(plan));
		//trace(state.aspects.at(winner_));
	}

	@Test
	public function swapActionTest():Void {
		// swapPiece, pickPiece

		configMaker.numPlayers = 2;
		configMaker.startingSwaps = 5;
		makeState();
		combinedRules.get("startAction").update();
		combinedRules.get("startAction").chooseOption();

		// loop
		// 	swap a piece
		// 	check the new piece, and the number of pieces that remain

	}

	@Test
	public function quitActionTest():Void {
		// forfeit, decay, cavity, killHeadlessPlayer, oneLivingPlayer, endTurn, replenish, pickPiece

		configMaker.numPlayers = 2;
		makeState();
		combinedRules.get("startAction").update();
		combinedRules.get("startAction").chooseOption();

		// Two player grab with cavity
		// Have one player forfeit
	}

	@Test
	public function dropActionTest():Void {
		// dropPiece, eatCells, decay, cavity, killHeadlessPlayer, oneLivingPlayer, endTurn, replenish, pickPiece, skipsExhausted

		configMaker.numPlayers = 2;
		configMaker.initGrid = TestBoards.twoPlayerGrab;
		makeState();
		combinedRules.get("startAction").update();
		combinedRules.get("startAction").chooseOption();

		// Have one player eat a limb of the other
		// Have the other player skip
		// Have the one player eat the head of the other
	}

	private function makeState():Void {
		basicRules = RuleFactory.makeBasicRules(configMaker.makeConfig(stateHistorian.history, stateHistorian.historyState));
		var basicRulesArray:Array<Rule> = [];
		var demiurgicRulesArray:Array<Rule> = [];
		var rules:Array<Rule> = [];
		for (key in basicRules.keys()) {
			var rule:Rule = basicRules.get(key);
			rules.push(rule);

			if (rule.demiurgic) demiurgicRulesArray.push(rule);
			else basicRulesArray.push(rule);
		}
		combinedRules = RuleFactory.combineRules(ScourgeConfigMaker.combinedRuleCfg, basicRules);
		plan = new StatePlanner().planState(state, rules);
		for (rule in demiurgicRulesArray) rule.prime(state, plan);
        for (rule in basicRulesArray) rule.prime(state, plan);
    }

}
