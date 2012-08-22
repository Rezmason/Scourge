package net.rezmason.scourge.model;

import massive.munit.Assert;

import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.Rule;
import net.rezmason.scourge.model.aspects.BodyAspect;
import net.rezmason.scourge.model.aspects.OwnershipAspect;
import net.rezmason.scourge.model.aspects.PlyAspect;
import net.rezmason.scourge.model.aspects.FreshnessAspect;
import net.rezmason.scourge.model.rules.KillDisconnectedCellsRule;
import net.rezmason.scourge.model.evaluators.TestEvaluator;
//import net.rezmason.scourge.model.GridNode;

using net.rezmason.scourge.model.GridUtils;

class RulesTest
{
	var history:History<Int>;

    var state:State;

	public function new() {

	}

	@BeforeClass
	public function beforeClass():Void {
		history = new History<Int>();
	}

	@AfterClass
	public function afterClass():Void {
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

		var numCells:Int = ~/([^0])/g.replace(TestBoards.spiral, "").length;

        var testEvaluator:Evaluator = new TestEvaluator();
        Assert.areEqual(numCells, testEvaluator.evaluate(state)); // 51 cells for player 0

        var ply:PlyAspect = cast state.aspects.get(PlyAspect.id);

        var body:BodyAspect = cast state.players[history.get(ply.currentPlayer)].get(BodyAspect.id);
		var playerHead:BoardNode = state.nodes[history.get(body.head)];
		var playerNeck:BoardNode = playerHead.n();
		var neckOwner:OwnershipAspect = cast playerNeck.value.get(OwnershipAspect.id);
        var neckFresh:FreshnessAspect = cast playerNeck.value.get(FreshnessAspect.id);

        // Cut the neck

		history.set(neckOwner.isFilled, 0);
		history.set(neckOwner.occupier, -1);
        history.set(neckFresh.freshness, 1);

        Assert.areEqual(1, testEvaluator.evaluate(state)); // only one cell for player 0

		//Pass the State to the Rule for Option generation

		var options:Array<Option> = killRule.getOptions(state);

        Assert.isNotNull(options);
		Assert.areEqual(1, options.length);

		var reviz:Int = history.revision;

		//trace(BoardUtils.spitGrid(playerHead, history));

		killRule.chooseOption(state, options[0]);

		//trace(BoardUtils.spitGrid(playerHead, history));

        numCells = ~/([^0])/g.replace(BoardUtils.spitGrid(playerHead, history), "").length;
		Assert.areEqual(1, numCells); // only one cell for player 0
	}

    @Test
    public function killDisconnectedCellsRuleTest2():Void {
        var killRule:KillDisconnectedCellsRule = new KillDisconnectedCellsRule();
        state = makeState(TestBoards.spiralPetri, 1, cast [killRule]);
        var numCells:Int = ~/([^0])/g.replace(TestBoards.spiralPetri, "").length;
        var testEvaluator:Evaluator = new TestEvaluator();

        Assert.areEqual(numCells, testEvaluator.evaluate(state)); // 51 cells for player 0

        var ply:PlyAspect = cast state.aspects.get(PlyAspect.id);

        var body:BodyAspect = cast state.players[history.get(ply.currentPlayer)].get(BodyAspect.id);
        var playerHead:BoardNode = state.nodes[history.get(body.head)];
        var playerNeck:BoardNode = playerHead.s();
        var neckOwner:OwnershipAspect = cast playerNeck.value.get(OwnershipAspect.id);
        var neckFresh:FreshnessAspect = cast playerNeck.value.get(FreshnessAspect.id);

        // Cut the neck

        history.set(neckOwner.isFilled, 0);
        history.set(neckOwner.occupier, -1);
        history.set(neckFresh.freshness, 1);

        //trace(BoardUtils.spitGrid(playerHead, history));
        killRule.chooseOption(state, killRule.getOptions(state)[0]);
        //trace(BoardUtils.spitGrid(playerHead, history));

        numCells = ~/([^0])/g.replace(BoardUtils.spitGrid(playerHead, history), "").length;
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

	private function makeState(initGrid:String, numPlayers:Int, rules:Array<Rule>):State {

		history.wipe();

        /*
        // make board config and generate board
        var boardCfg:BoardConfig = new BoardConfig();
        boardCfg.numPlayers = numPlayers;
        boardCfg.circular = false;
        boardCfg.initGrid = initGrid;
        var boardFactory:BoardFactory = new BoardFactory();
        var boardData:BoardData = boardFactory.makeBoard(boardCfg, history);
        */

        // make state config and generate state
        var factory:StateFactory = new StateFactory();
        var stateCfg:StateConfig = new StateConfig();
        //stateCfg.playerHeads = boardData.heads;
        stateCfg.numPlayers = numPlayers;
        stateCfg.rules = rules;
        //stateCfg.nodes = boardData.nodes;

        return factory.makeState(stateCfg, history);
	}
}
