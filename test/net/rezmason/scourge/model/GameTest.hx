package net.rezmason.scourge.model;

import massive.munit.Assert;
import massive.munit.async.AsyncFactory;
import massive.munit.util.Timer;
import net.rezmason.ropes.ModelTypes;
import net.rezmason.ropes.State;
import net.rezmason.ropes.StateHistorian;
import net.rezmason.ropes.StatePlanner;
import net.rezmason.ropes.Rule;
import net.rezmason.ropes.RuleFactory;
import net.rezmason.ropes.Aspect;
import net.rezmason.scourge.model.ScourgeConfigMaker;
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

    var startAction:Rule;
    var biteAction:Rule;
    var swapAction:Rule;
    var quitAction:Rule;
    var dropAction:Rule;

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
		Assert.isNotNull(combinedRules.get(ScourgeConfigMaker.startAction));
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

		startAction.update();
		startAction.chooseOption();

		//trace(state.spitBoard(plan));
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

		configMaker.numPlayers = 2;
		configMaker.startingBites = 5;
		configMaker.initGrid = TestBoards.twoPlayerGrab;
		makeState();

		var winner_:AspectPtr = plan.onState(WinAspect.WINNER);
		var totalArea_:AspectPtr = plan.onPlayer(BodyAspect.TOTAL_AREA);
		var currentPlayer_:AspectPtr = plan.onState(PlyAspect.CURRENT_PLAYER);

		startAction.update();
		startAction.chooseOption();

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

		configMaker.pieceHatSize = 3;
		configMaker.startingSwaps = 6;
		configMaker.allowFlipping = true;

		makeState();
		startAction.update();
		startAction.chooseOption();

		var numSwaps_:AspectPtr = plan.onPlayer(SwapAspect.NUM_SWAPS);
		var pieceTableID_:AspectPtr = plan.onState(PieceAspect.PIECE_TABLE_ID);

		Assert.areEqual(configMaker.startingSwaps, state.players[0].at(numSwaps_));

		var pickedPieces:Array<Null<Int>> = [];

		for (ike in 0...configMaker.startingSwaps) {
			swapAction.update();
			swapAction.chooseOption();

			var piece:Int = state.aspects.at(pieceTableID_);

			Assert.areEqual(configMaker.pieceTableIDs[(ike + 1) % configMaker.pieceHatSize], state.aspects.at(pieceTableID_));

			var index:Int = ike % configMaker.pieceHatSize;
			if (pickedPieces[index] == null) pickedPieces[index] = piece;
			else Assert.areEqual(pickedPieces[index], piece);
		}

		Assert.areEqual(0, state.players[0].at(numSwaps_));
	}

	@Test
	public function quitActionTest():Void {
		// forfeit, decay, cavity, killHeadlessPlayer, oneLivingPlayer, endTurn, replenish, pickPiece

		configMaker.numPlayers = 2;
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

		configMaker.numPlayers = 2;
		configMaker.pieceTableIDs = [Pieces.getPieceIdBySizeAndIndex(4, 1)]; // "L/J block"
		configMaker.initGrid = TestBoards.twoPlayerGrab;
		makeState();
		startAction.update();
		startAction.chooseOption();

		var occupier_:AspectPtr = plan.onNode(OwnershipAspect.OCCUPIER);

		//trace(state.spitBoard(plan));

		dropAction.update();
		dropAction.chooseOption(35); // drop, eat

		//trace(state.spitBoard(plan));

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

		//trace(state.spitBoard(plan));

		var winner_:AspectPtr = plan.onState(WinAspect.WINNER);

		Assert.areEqual(0, state.aspects.at(winner_));
	}

	private function makeState():Void {
		basicRules = RuleFactory.makeBasicRules(ScourgeConfigMaker.ruleDefs, configMaker.makeConfig(stateHistorian.history, stateHistorian.historyState));
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
        startAction = combinedRules.get(ScourgeConfigMaker.startAction);
	    biteAction = combinedRules.get("biteAction");
	    swapAction = combinedRules.get("swapAction");
	    quitAction = combinedRules.get("quitAction");
	    dropAction = combinedRules.get("dropAction");
    }

}
