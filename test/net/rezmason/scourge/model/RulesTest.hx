package net.rezmason.scourge.model;

import massive.munit.Assert;

import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.aspects.BodyAspect;
import net.rezmason.scourge.model.aspects.OwnershipAspect;
import net.rezmason.scourge.model.aspects.PlyAspect;
import net.rezmason.scourge.model.aspects.FreshnessAspect;
import net.rezmason.scourge.model.rules.KillDisconnectedCellsRule;
import net.rezmason.scourge.model.rules.BuildBoardRule;
import net.rezmason.scourge.model.evaluators.TestEvaluator;
//import net.rezmason.scourge.model.GridNode;

using net.rezmason.scourge.model.GridUtils;

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

        var currentPlayer:Int = state.aspects[currentPlayer_];

        var head:Int = history.get(state.players[currentPlayer][BodyAspect.HEAD.id]);
        var playerHead:BoardNode = state.nodes[head];
		var playerNeck:BoardNode = playerHead.n();

        // Cut the neck

		history.set(playerNeck.value[isFilled_], 0);
		history.set(playerNeck.value[occupier_], -1);
        history.set(playerNeck.value[freshness_], 1);

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

        var currentPlayer:Int = state.aspects[currentPlayer_];

        var head:Int = history.get(state.players[currentPlayer][BodyAspect.HEAD.id]);
        var playerHead:BoardNode = state.nodes[head];
        var playerNeck:BoardNode = playerHead.s();

        // Cut the neck

        history.set(playerNeck.value[isFilled_], 0);
        history.set(playerNeck.value[occupier_], -1);
        history.set(playerNeck.value[freshness_], 1);

        //trace(BoardUtils.spitBoard(state));
        killRule.chooseOption(killRule.getOptions()[0]);
        //trace(BoardUtils.spitBoard(state));

        numCells = ~/([^0])/g.replace(BoardUtils.spitBoard(state), "").length;
        Assert.areEqual(1, numCells); // only one cell for player 0
    }

	//@Test
	public function placePieceRuleTest():Void {
		state = makeState(TestBoards.fourSquares, 4, cast []);
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

	private function makeState(initGrid:String, numPlayers:Int, otherRules:Array<Rule>):State {

		history.wipe();

        // make board config and generate board
        var boardCfg:BoardConfig = new BoardConfig();
        boardCfg.circular = false;
        boardCfg.initGrid = initGrid;

        otherRules.unshift(new BuildBoardRule(boardCfg));

        // make state config and generate state
        var factory:StateFactory = new StateFactory();
        var stateCfg:StateConfig = new StateConfig();
        //stateCfg.playerHeads = boardData.heads;
        stateCfg.numPlayers = numPlayers;
        stateCfg.rules = otherRules;
        //stateCfg.nodes = boardData.nodes;

        return factory.makeState(stateCfg, history);
	}
}
