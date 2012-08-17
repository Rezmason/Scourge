package net.rezmason.scourge.model;

import massive.munit.Assert;

import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.Rule;
import net.rezmason.scourge.model.rules.KillDisconnectedCellsRule;

class RulesTest
{
	var history:History<Int>;
    var historyArray:Array<Int>;
    var genes:Array<String>;

    var state:State;

	public function new() {

	}

	@BeforeClass
	public function beforeClass():Void {
		history = new History<Int>();
        historyArray = history.array;
        genes = ["a", "b"];
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
		state = makeState(TestBoards.spiral, cast [new KillDisconnectedCellsRule()]);

		//Pass the State to the Rule for Option generation
			//returns one Option, which is the expected Option
		//Pass State, Evaluator and Option to Rule
			//returns an expected value
		//Pass the State and Option to the Rule
		//Compare the State with the expected result
	}

	@Test
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
