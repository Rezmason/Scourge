package net.rezmason.scourge.model;

import massive.munit.Assert;

import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.Rule;
import net.rezmason.scourge.model.aspects.OwnershipAspect;
import net.rezmason.scourge.model.rules.KillDisconnectedCellsRule;
import net.rezmason.scourge.model.evaluators.TestEvaluator;

using net.rezmason.scourge.model.GridUtils;

class RulesTest
{
	var history:History<Int>;
    var historyArray:Array<Int>;
    var allocator:HistoryAllocator;
    var genes:Array<String>;

    var state:State;

	public function new() {

	}

	@BeforeClass
	public function beforeClass():Void {
		history = new History<Int>();
        historyArray = history.array;
        allocator = history.alloc;
        genes = ["a", "b", "c", "d"];
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

		var killRule:KillDisconnectedCellsRule = new KillDisconnectedCellsRule(historyArray);
		state = makeState(TestBoards.spiral, cast [killRule]);

		var playerIndex:Int = 0;

        var numCells:Int = ~/([^0])/g.replace(TestBoards.spiral, "").length;

        var testEvaluator:Evaluator = new TestEvaluator(historyArray);
        Assert.areEqual(numCells, testEvaluator.evaluate(playerIndex, state)); // only one cell for player 0

		var playerHead:BoardNode = state.players[playerIndex].head;
		var playerNeck:BoardNode = playerHead.n();
		var neckOwner:OwnershipAspect = cast playerNeck.value.get(OwnershipAspect.id);

		// Cut the neck

		historyArray[neckOwner.isFilled] = 0;
		historyArray[neckOwner.occupier] = -1;

		//Pass the State to the Rule for Option generation

		var options:Array<Option> = killRule.getOptions(state);

        Assert.isNotNull(options);
		Assert.areEqual(1, options.length);

		var reviz:Int = history.revision;

		trace(BoardUtils.spitGrid(playerHead, historyArray));

		killRule.chooseOption(state, options[0]);

		trace(BoardUtils.spitGrid(playerHead, historyArray));

		Assert.areEqual(1, testEvaluator.evaluate(playerIndex, state)); // only one cell for player 0
	}

	//@Test
	public function placePieceRuleTest():Void {
		state = makeState(TestBoards.fourSquares, cast []);
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

	private function makeState(initGrid:String, rules:Array<Rule>):State {

		history.wipe();

		// make board config and generate board
        var boardCfg:BoardConfig = new BoardConfig();
        boardCfg.numPlayers = genes.length;
        boardCfg.circular = false;
        boardCfg.initGrid = initGrid;
        var boardFactory:BoardFactory = new BoardFactory();
        var heads:Array<BoardNode> = boardFactory.makeBoard(boardCfg, history);

		// make state config and generate state
        var factory:StateFactory = new StateFactory();
        var stateCfg:StateConfig = new StateConfig();
        stateCfg.playerHeads = heads;
        stateCfg.playerGenes = genes;
        stateCfg.rules = rules;

        return factory.makeState(stateCfg, history);
	}
}
