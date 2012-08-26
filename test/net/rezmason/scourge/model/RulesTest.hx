package net.rezmason.scourge.model;

import massive.munit.Assert;

import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.aspects.BodyAspect;
import net.rezmason.scourge.model.aspects.OwnershipAspect;
import net.rezmason.scourge.model.aspects.PlyAspect;
import net.rezmason.scourge.model.aspects.FreshnessAspect;
import net.rezmason.scourge.model.rules.KillDisconnectedCellsRule;
import net.rezmason.scourge.model.rules.EatCellsRule;
import net.rezmason.scourge.model.rules.BuildBoardRule;
import net.rezmason.scourge.model.rules.DraftPlayersRule;
import net.rezmason.scourge.model.evaluators.TestEvaluator;
import net.rezmason.scourge.model.GridNode;

using net.rezmason.scourge.model.GridUtils;
using net.rezmason.utils.Pointers;

class RulesTest
{
	var history:StateHistory;

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

	@Before
	public function setup():Void {

	}

	@After
	public function tearDown():Void {
	}


	@Test
	public function killDisconnectedCellsRuleTest():Void {

		var killRule:KillDisconnectedCellsRule = new KillDisconnectedCellsRule();
		state = makeState(TestBoards.spiral, 4, cast [killRule]);

        var occupier_:AspectPtr = state.nodeAspectLookup[OwnershipAspect.OCCUPIER.id];
        var isFilled_:AspectPtr = state.nodeAspectLookup[OwnershipAspect.IS_FILLED.id];
        var freshness_:AspectPtr = state.nodeAspectLookup[FreshnessAspect.FRESHNESS.id];
        var head_:AspectPtr = state.playerAspectLookup[BodyAspect.HEAD.id];
        var currentPlayer_:AspectPtr = state.stateAspectLookup[PlyAspect.CURRENT_PLAYER.id];


		var numCells:Int = ~/([^0])/g.replace(TestBoards.spiral, "").length;

        var testEvaluator:Evaluator = new TestEvaluator();

        Assert.areEqual(numCells, testEvaluator.evaluate(state)); // 51 cells for player 0

        var currentPlayer:Int = history.get(state.aspects.at(currentPlayer_));

        var head:Int = history.get(state.players[currentPlayer][BodyAspect.HEAD.id]);
        var playerHead:BoardNode = state.nodes[head];
		var playerNeck:BoardNode = playerHead.n();

        // Cut the neck

		history.set(playerNeck.value.at(isFilled_), 0);
		history.set(playerNeck.value.at(occupier_), -1);
        history.set(playerNeck.value.at(freshness_), 1);

        Assert.areEqual(1, testEvaluator.evaluate(state)); // only one cell for player 0

		//Pass the State to the Rule for Option generation

		var options:Array<Option> = killRule.getOptions();

        Assert.isNotNull(options);
		Assert.areEqual(1, options.length);

		var reviz:Int = history.revision;

		//trace(BoardUtils.spitBoard(state));
		killRule.chooseOption(options[0]);
		//trace(BoardUtils.spitBoard(state));

        numCells = ~/([^0])/g.replace(BoardUtils.spitBoard(state), "").length;
		Assert.areEqual(1, numCells); // only one cell for player 0
	}

    @Test
    public function killDisconnectedCellsRuleTest2():Void {

        var killRule:KillDisconnectedCellsRule = new KillDisconnectedCellsRule();
        state = makeState(TestBoards.spiralPetri, 1, cast [killRule]);

        var occupier_:AspectPtr = state.nodeAspectLookup[OwnershipAspect.OCCUPIER.id];
        var isFilled_:AspectPtr = state.nodeAspectLookup[OwnershipAspect.IS_FILLED.id];
        var freshness_:AspectPtr = state.nodeAspectLookup[FreshnessAspect.FRESHNESS.id];
        var head_:AspectPtr = state.playerAspectLookup[BodyAspect.HEAD.id];
        var currentPlayer_:AspectPtr = state.stateAspectLookup[PlyAspect.CURRENT_PLAYER.id];

        var numCells:Int = ~/([^0])/g.replace(TestBoards.spiralPetri, "").length;
        var testEvaluator:Evaluator = new TestEvaluator();

        Assert.areEqual(numCells, testEvaluator.evaluate(state)); // 51 cells for player 0

        var currentPlayer:Int = history.get(state.aspects.at(currentPlayer_));

        var head:Int = history.get(state.players[currentPlayer].at(head_));
        var playerHead:BoardNode = state.nodes[head];
        var playerNeck:BoardNode = playerHead.s();

        // Cut the neck

        history.set(playerNeck.value.at(isFilled_), 0);
        history.set(playerNeck.value.at(occupier_), -1);
        history.set(playerNeck.value.at(freshness_), 1);

        //trace(BoardUtils.spitBoard(state));
        killRule.chooseOption(killRule.getOptions()[0]);
        //trace(BoardUtils.spitBoard(state));

        numCells = ~/([^0])/g.replace(BoardUtils.spitBoard(state), "").length;
        Assert.areEqual(1, numCells); // only one cell for player 0
    }

    @Test
    public function eatRuleTest():Void {
        var eatConfig:EatCellsConfig = new EatCellsConfig();
        eatConfig.recursive = false;
        var eatRule:EatCellsRule = new EatCellsRule(eatConfig);
        state = makeState(TestBoards.oaf, 4, cast [eatRule]);

        // set up the board for the test

        var occupier_:AspectPtr = state.nodeAspectLookup[OwnershipAspect.OCCUPIER.id];
        var isFilled_:AspectPtr = state.nodeAspectLookup[OwnershipAspect.IS_FILLED.id];
        var freshness_:AspectPtr = state.nodeAspectLookup[FreshnessAspect.FRESHNESS.id];
        var head_:AspectPtr = state.playerAspectLookup[BodyAspect.HEAD.id];
        var currentPlayer_:AspectPtr = state.stateAspectLookup[PlyAspect.CURRENT_PLAYER.id];
        var currentPlayer:Int = history.get(state.aspects.at(currentPlayer_));
        var head:Int = history.get(state.players[currentPlayer].at(head_));
        var playerHead:BoardNode = state.nodes[head];

        var spitAspectProperties:IntHash<String> = new IntHash<String>();
        spitAspectProperties.set(FreshnessAspect.FRESHNESS.id, "F");

        var cursor:BoardNode = playerHead;
        cursor = cursor.run(Gr.n, 12).run(Gr.e, 6);

        history.set(cursor.value.at(freshness_), 1);

        cursor = cursor.run(Gr.s, 2).run(Gr.e, 2);

        history.set(cursor.value.at(isFilled_), 0);
        history.set(cursor.value.at(occupier_), -1);

        var numCells:Int = ~/([^0])/g.replace(BoardUtils.spitBoard(state), "").length;
        Assert.areEqual(371, numCells);

        // straight up eating

        //trace(BoardUtils.spitBoard(state, true, spitAspectProperties));
        eatRule.chooseOption(eatRule.getOptions()[0]);
        //trace(BoardUtils.spitBoard(state, true, spitAspectProperties));

        numCells = ~/([^0])/g.replace(BoardUtils.spitBoard(state), "").length;
        Assert.areEqual(389, numCells);
    }

    @Test
    public function eatRecursivelyRuleTest():Void {
        var eatConfig:EatCellsConfig = new EatCellsConfig();
        eatConfig.recursive = true;
        var eatRule:EatCellsRule = new EatCellsRule(eatConfig);
        state = makeState(TestBoards.oaf, 4, cast [eatRule]);

        // set up the board for the test

        var occupier_:AspectPtr = state.nodeAspectLookup[OwnershipAspect.OCCUPIER.id];
        var isFilled_:AspectPtr = state.nodeAspectLookup[OwnershipAspect.IS_FILLED.id];
        var freshness_:AspectPtr = state.nodeAspectLookup[FreshnessAspect.FRESHNESS.id];
        var head_:AspectPtr = state.playerAspectLookup[BodyAspect.HEAD.id];
        var currentPlayer_:AspectPtr = state.stateAspectLookup[PlyAspect.CURRENT_PLAYER.id];
        var currentPlayer:Int = history.get(state.aspects.at(currentPlayer_));
        var head:Int = history.get(state.players[currentPlayer].at(head_));
        var playerHead:BoardNode = state.nodes[head];

        var spitAspectProperties:IntHash<String> = new IntHash<String>();
        spitAspectProperties.set(FreshnessAspect.FRESHNESS.id, "F");

        var cursor:BoardNode = playerHead;
        cursor = cursor.run(Gr.n, 12).run(Gr.e, 6);

        history.set(cursor.value.at(freshness_), 1);

        cursor = cursor.run(Gr.s, 2).run(Gr.e, 2);

        history.set(cursor.value.at(isFilled_), 0);
        history.set(cursor.value.at(occupier_), -1);

        var numCells:Int = ~/([^0])/g.replace(BoardUtils.spitBoard(state), "").length;
        Assert.areEqual(371, numCells);

        // recursive eating

        //trace(BoardUtils.spitBoard(state, true, spitAspectProperties));
        eatRule.chooseOption(eatRule.getOptions()[0]);
        //trace(BoardUtils.spitBoard(state, true, spitAspectProperties));

        numCells = ~/([^0])/g.replace(BoardUtils.spitBoard(state), "").length;
        Assert.areEqual(483, numCells);
    }

	//@Test
	public function placePieceRuleTest():Void {
		/*
		1: for each orientation,
		2: for each edge node of the player,
			3: for each neighbor coord in the orientation,
				Look up the node at the origin
				If that node has not already been visited as an origin,
					Flag that node
					4: for each coord in the orientation,
						Get the node at the coord (relative to the origin node)
						If the node is filled,
							break loop 3
					add the origin node to the list
		unflag all flagged nodes
		*/
	}

    private function makeState(initGrid:String, numPlayers:Int, rules:Array<Rule>):State {

		history.wipe();

        // make player config and generate players
        var playerCfg:PlayerConfig = new PlayerConfig();
        playerCfg.numPlayers = numPlayers;

        var draftPlayersRule:DraftPlayersRule = new DraftPlayersRule(playerCfg);

        // make board config and generate board
        var boardCfg:BoardConfig = new BoardConfig();
        boardCfg.initGrid = initGrid;

        var buildBoardRule:BuildBoardRule = new BuildBoardRule(boardCfg);

        rules.unshift(buildBoardRule);
        rules.unshift(draftPlayersRule);

        // make state config and generate state
        var factory:StateFactory = new StateFactory();
        var stateCfg:StateConfig = new StateConfig();
        stateCfg.rules = rules;

        return factory.makeState(stateCfg, history);
	}
}
