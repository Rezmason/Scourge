package net.rezmason.scourge.model;

import massive.munit.Assert;
import massive.munit.async.AsyncFactory;
import massive.munit.util.Timer;
import net.rezmason.ropes.Types;
import net.rezmason.ropes.State;
import net.rezmason.ropes.StateHistorian;
import net.rezmason.ropes.StatePlanner;
import net.rezmason.ropes.Rule;
import net.rezmason.ropes.RuleFactory;
import net.rezmason.ropes.Aspect;
import net.rezmason.scourge.model.ScourgeConfig;
import net.rezmason.scourge.model.ScourgeConfigFactory;
import net.rezmason.scourge.model.aspects.BodyAspect;
import net.rezmason.scourge.model.aspects.OwnershipAspect;
import net.rezmason.scourge.model.aspects.PieceAspect;
import net.rezmason.scourge.model.aspects.PlyAspect;
import net.rezmason.scourge.model.aspects.SwapAspect;
import net.rezmason.scourge.model.aspects.WinAspect;
import net.rezmason.scourge.model.rules.DropPieceRule;

using net.rezmason.scourge.model.BoardUtils;
using net.rezmason.ropes.GridUtils;
using net.rezmason.ropes.StatePlan;
using net.rezmason.utils.Alphabetizer;
using net.rezmason.utils.Pointers;

class ScourgeConfigFactoryTest
{
	var stateHistorian:StateHistorian;
    var history:StateHistory;
    var state:State;
    var historyState:State;
    var plan:StatePlan;
    var config:ScourgeConfig;
    var basicRules:Hash<Rule>;
    var combinedRules:Hash<Rule>;

    var startAction:Rule;
    var biteAction:Rule;
    var swapAction:Rule;
    var quitAction:Rule;
    var dropAction:Rule;

	public function new() {

	}

	@BeforeClass
	public function beforeClass():Void {
		config = ScourgeConfigFactory.makeDefaultConfig();
		stateHistorian = new StateHistorian();

        history = stateHistorian.history;
        state = stateHistorian.state;
        historyState = stateHistorian.historyState;
	}

	@AfterClass
	public function afterClass():Void {
		stateHistorian.reset();

		basicRules = null;
		combinedRules = null;
		config = null;
		stateHistorian = null;
		history = null;
        historyState = null;
        state = null;
        plan = null;
	}

	@Before
	public function setup():Void {
		config = ScourgeConfigFactory.makeDefaultConfig();
		stateHistorian.reset();

		basicRules = null;
		combinedRules = null;
	}

	@Test
	public function allActionsRegisteredTest():Void {
		makeState();
		for (action in ScourgeConfigFactory.makeActionList(config)) Assert.isNotNull(combinedRules.get(action));
		Assert.isNotNull(combinedRules.get(ScourgeConfigFactory.makeStartAction()));
	}

	@Test
	public function startActionTest():Void {
		// decay, cavity, killHeadlessPlayer, oneLivingPlayer, pickPiece

		config.numPlayers = 2;
		config.initGrid = TestBoards.twoPlayerBullshit;
		makeState();

		VisualAssert.assert("floating zero square, stringy player one with no head", state.spitBoard(plan));

		var num0Cells:Int = ~/([^0])/g.replace(state.spitBoard(plan, false), "").length;
		var num1Cells:Int = ~/([^1])/g.replace(state.spitBoard(plan, false), "").length;

		Assert.areEqual(24, num0Cells);
		Assert.areEqual(32, num1Cells);

		startAction.update();
		startAction.chooseOption();

		VisualAssert.assert("big square player zero with cavity, no player one", state.spitBoard(plan));

		var num0Cells:Int = ~/([^0])/g.replace(state.spitBoard(plan, false), "").length;
		var num1Cells:Int = ~/([^1])/g.replace(state.spitBoard(plan, false), "").length;

		Assert.areEqual(20, num0Cells);
		Assert.areEqual(0, num1Cells);

		var totalArea_:AspectPtr = plan.onPlayer(BodyAspect.TOTAL_AREA);
		var head_:AspectPtr = plan.onPlayer(BodyAspect.HEAD);

		var winner_:AspectPtr = plan.onState(WinAspect.WINNER);
		var currentPlayer_:AspectPtr = plan.onState(PlyAspect.CURRENT_PLAYER);

		Assert.areEqual(36, state.players[0].at(totalArea_));
		Assert.areEqual(Aspect.NULL, state.players[1].at(head_));
		Assert.areEqual(0, state.aspects.at(winner_));
		Assert.areEqual(0, state.aspects.at(currentPlayer_));
	}

	@Test
	public function biteActionTest():Void {

		// bite, decay, cavity, killHeadlessPlayer, oneLivingPlayer

		config.numPlayers = 2;
		config.startingBites = 5;
		config.initGrid = TestBoards.twoPlayerGrab;
		makeState();

		VisualAssert.assert("two player grab", state.spitBoard(plan));

		var winner_:AspectPtr = plan.onState(WinAspect.WINNER);
		var totalArea_:AspectPtr = plan.onPlayer(BodyAspect.TOTAL_AREA);
		var currentPlayer_:AspectPtr = plan.onState(PlyAspect.CURRENT_PLAYER);

		startAction.update();
		startAction.chooseOption();

		Assert.areEqual(13, state.players[1].at(totalArea_));

		VisualAssert.assert("two player grab", state.spitBoard(plan));

		biteAction.update();
		biteAction.chooseOption(4); // bite

		Assert.areEqual(6, state.players[1].at(totalArea_));

		VisualAssert.assert("player zero bit off player one's leg", state.spitBoard(plan));

		VisualAssert.assert("no difference", state.spitBoard(plan));

		// How about some skipping?
		dropAction.update();
		dropAction.chooseOption(); // skip

		VisualAssert.assert("no difference", state.spitBoard(plan));

		dropAction.update();
		dropAction.chooseOption(); // skip

		biteAction.update();
		biteAction.chooseOption(); // bite head

		Assert.areEqual(0, state.players[1].at(totalArea_));

		VisualAssert.assert("player zero bit player one in the head: dead", state.spitBoard(plan));
	}

	@Test
	public function swapActionTest():Void {

		// swapPiece, pickPiece

		config.pieceHatSize = 3;
		config.startingSwaps = 6;
		config.allowFlipping = true;

		makeState();
		startAction.update();
		startAction.chooseOption();

		var numSwaps_:AspectPtr = plan.onPlayer(SwapAspect.NUM_SWAPS);
		var pieceTableID_:AspectPtr = plan.onState(PieceAspect.PIECE_TABLE_ID);

		Assert.areEqual(config.startingSwaps, state.players[0].at(numSwaps_));

		var pickedPieces:Array<Null<Int>> = [];

		for (ike in 0...config.startingSwaps) {
			swapAction.update();
			swapAction.chooseOption();

			var piece:Int = state.aspects.at(pieceTableID_);

			Assert.areEqual(config.pieceTableIDs[(ike + 1) % config.pieceHatSize], state.aspects.at(pieceTableID_));

			var index:Int = ike % config.pieceHatSize;
			if (pickedPieces[index] == null) pickedPieces[index] = piece;
			else Assert.areEqual(pickedPieces[index], piece);
		}

		Assert.areEqual(0, state.players[0].at(numSwaps_));
	}

	@Test
	public function quitActionTest():Void {

		// forfeit, decay, cavity, killHeadlessPlayer, oneLivingPlayer, endTurn, replenish, pickPiece

		config.numPlayers = 2;
		makeState();
		startAction.update();
		startAction.chooseOption();

		quitAction.update();
		quitAction.chooseOption(); // player 1 ragequits

		var winner_:AspectPtr = plan.onState(WinAspect.WINNER);

		Assert.areEqual(1, state.aspects.at(winner_));
	}

	@Test
	public function dropActionTest():Void {

		// dropPiece, eatCells, decay, cavity, killHeadlessPlayer, oneLivingPlayer, endTurn, replenish, pickPiece, skipsExhausted

		config.numPlayers = 2;
		config.pieceTableIDs = [Pieces.getPieceIdBySizeAndIndex(4, 1)]; // "L/J block"
		config.initGrid = TestBoards.twoPlayerGrab;
		makeState();
		startAction.update();
		startAction.chooseOption();

		var occupier_:AspectPtr = plan.onNode(OwnershipAspect.OCCUPIER);

		VisualAssert.assert("two player grab", state.spitBoard(plan));

		dropAction.update();
		dropAction.chooseOption(35); // drop, eat

		VisualAssert.assert("player zero dropped an L, ate player one's leg; small new cavity", state.spitBoard(plan));

		dropAction.update();
		dropAction.chooseOption(); // skip

		var head_:AspectPtr = plan.onPlayer(BodyAspect.HEAD);

		dropAction.update();
		dropAction.chooseOption(32); // drop, eat, kill

		/*
		var head_:AspectPtr = plan.onPlayer(BodyAspect.HEAD);
		var enemyHead:BoardNode = state.nodes[state.players[1].at(head_)];

		var droptions:Array<DropPieceOption> = cast dropAction.options;
		var bestOption:DropPieceOption = null;
		for (option in droptions) {
			if (!option.duplicate) {
				for (nodeID in option.addedNodes) {
					var node:BoardNode = state.nodes[nodeID];
					for (neighbor in node.allNeighbors()) {
						if (neighbor == enemyHead) {
							bestOption = option;
							break;
						}
					}
				}
			}
			if (bestOption != null) break;
		}

		trace(bestOption);
		*/

		VisualAssert.assert("player zero dropped another L, ate player one's head and body; another cavity", state.spitBoard(plan));

		var winner_:AspectPtr = plan.onState(WinAspect.WINNER);
		Assert.areEqual(0, state.aspects.at(winner_));
	}

	private function makeState():Void {
		var ruleConfig:Dynamic = ScourgeConfigFactory.makeRuleConfig(config, randomFunction, stateHistorian.history, stateHistorian.historyState);
		basicRules = RuleFactory.makeBasicRules(ScourgeConfigFactory.ruleDefs, ruleConfig);
		var basicRulesArray:Array<Rule> = [];
		var demiurgicRules:Hash<Rule> = new Hash<Rule>();
		var rules:Array<Rule> = [];
		for (key in basicRules.keys().a2z()) {
			var rule:Rule = basicRules.get(key);
			rules.push(rule);

			if (rule.demiurgic) demiurgicRules.set(key, rule);
			else basicRulesArray.push(rule);
		}

		combinedRules = RuleFactory.combineRules(ScourgeConfigFactory.makeCombinedRuleCfg(config), basicRules);

		plan = new StatePlanner().planState(state, rules);
		for (key in ScourgeConfigFactory.makeDemiurgicRuleList()) demiurgicRules.get(key).prime(state, plan);
        for (rule in basicRulesArray) rule.prime(state, plan);
        startAction = combinedRules.get(ScourgeConfigFactory.makeStartAction());
	    biteAction = combinedRules.get("biteAction");
	    swapAction = combinedRules.get("swapAction");
	    quitAction = combinedRules.get("quitAction");
	    dropAction = combinedRules.get("dropAction");
    }

    private function randomFunction():Float { return 0; }

}
