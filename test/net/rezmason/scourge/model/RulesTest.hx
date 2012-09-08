package net.rezmason.scourge.model;

import massive.munit.Assert;

import net.rezmason.scourge.model.GridNode;
import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.aspects.BodyAspect;
import net.rezmason.scourge.model.aspects.FreshnessAspect;
import net.rezmason.scourge.model.aspects.OwnershipAspect;
import net.rezmason.scourge.model.aspects.PieceAspect;
import net.rezmason.scourge.model.aspects.PlyAspect;
import net.rezmason.scourge.model.evaluators.TestEvaluator;
import net.rezmason.scourge.model.rules.BuildBoardRule;
import net.rezmason.scourge.model.rules.DraftPlayersRule;
import net.rezmason.scourge.model.rules.EatCellsRule;
import net.rezmason.scourge.model.rules.KillDisconnectedCellsRule;
import net.rezmason.scourge.model.rules.TestPieceRule;
import net.rezmason.scourge.model.rules.DropPieceRule;

using net.rezmason.scourge.model.GridUtils;
using net.rezmason.utils.Pointers;

class RulesTest
{
	var history:StateHistory;
    var time:Float;

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
        time = massive.munit.util.Timer.stamp();
    }

    @After
    public function tearDown():Void {
        time = massive.munit.util.Timer.stamp() - time;
        trace("tick " + time);
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
        Assert.areEqual(51, numCells); // 51 cells for player 0

        var currentPlayer:Int = history.get(state.aspects.at(currentPlayer_));

        var head:Int = history.get(state.players[currentPlayer].at(head_));
        var playerHead:BoardNode = state.nodes[head];
		var playerNeck:BoardNode = playerHead.n();

        // Cut the neck

		history.set(playerNeck.value.at(isFilled_), 0);
		history.set(playerNeck.value.at(occupier_), -1);
        history.set(playerNeck.value.at(freshness_), 1);

		//Pass the State to the Rule for Option generation

		var options:Array<Option> = killRule.getOptions();

        Assert.isNotNull(options);
		Assert.areEqual(1, options.length);

		var reviz:Int = history.revision;

		//trace(BoardUtils.spitBoard(state));
		killRule.chooseOption(0);
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

        Assert.areEqual(17, numCells); // 51 cells for player 0

        var currentPlayer:Int = history.get(state.aspects.at(currentPlayer_));

        var head:Int = history.get(state.players[currentPlayer].at(head_));
        var playerHead:BoardNode = state.nodes[head];
        var playerNeck:BoardNode = playerHead.s();

        // Cut the neck

        history.set(playerNeck.value.at(isFilled_), 0);
        history.set(playerNeck.value.at(occupier_), -1);
        history.set(playerNeck.value.at(freshness_), 1);

        //trace(BoardUtils.spitBoard(state));
        killRule.chooseOption(0);
        //trace(BoardUtils.spitBoard(state));

        numCells = ~/([^0])/g.replace(BoardUtils.spitBoard(state), "").length;
        Assert.areEqual(1, numCells); // only one cell for player 0
    }

    @Test
    public function eatRuleTest():Void {
        var eatConfig:EatCellsConfig = {recursive:false};
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

        Assert.areEqual(1, eatRule.getOptions().length);

        // straight up eating

        //trace(BoardUtils.spitBoard(state, true, spitAspectProperties));
        eatRule.chooseOption(0);
        //trace(BoardUtils.spitBoard(state, true, spitAspectProperties));

        numCells = ~/([^0])/g.replace(BoardUtils.spitBoard(state), "").length;
        Assert.areEqual(389, numCells);
    }

    @Test
    public function eatRecursivelyRuleTest():Void {
        var eatConfig:EatCellsConfig = {recursive:true};
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
        eatRule.chooseOption(0);
        //trace(BoardUtils.spitBoard(state, true, spitAspectProperties));

        numCells = ~/([^0])/g.replace(BoardUtils.spitBoard(state), "").length;
        Assert.areEqual(483, numCells);
    }

	@Test
	public function placePieceRuleTest1():Void {

        var pieceSize:Int = 4;

        // An L/J block has nine neighbor cells.
        // Reflection allowed   rotation allowed    option count
        // N                    N                   9
        // Y                    N                   18
        // N                    Y                   36
        // Y                    Y                   72

        var testPieceCfg:TestPieceConfig = {
            pieceID:Pieces.getPieceIdBySizeAndIndex(pieceSize, 1), // "L/J block"
            reflection:0,
            rotation:0,
        };
        var testPieceRule:TestPieceRule = new TestPieceRule(testPieceCfg);

        var dropConfig:DropPieceConfig = {overlapSelf:false, allowFlipping:true, allowRotating:true};
        var dropRule:DropPieceRule = new DropPieceRule(dropConfig);
        state = makeState(TestBoards.emptyPetri, 1, [testPieceRule, dropRule]);

        var options:Array<DropPieceOption> = cast dropRule.getOptions();

        Assert.areEqual(72, options.length);

        var numCells:Int = ~/([^0])/g.replace(BoardUtils.spitBoard(state), "").length;
        Assert.areEqual(1, numCells); // 1 cell for player 0

        trace(BoardUtils.spitBoard(state));
        dropRule.chooseOption(0);
        trace(BoardUtils.spitBoard(state));

        numCells = ~/([^0])/g.replace(BoardUtils.spitBoard(state), "").length;
        Assert.areEqual(1 + pieceSize, numCells); // 5 cells for player 0
	}

    private function makeState(initGrid:String, numPlayers:Int, rules:Array<Rule>):State {

		history.wipe();

        // make player config and generate players
        var playerCfg:PlayerConfig = {numPlayers:numPlayers};
        var draftPlayersRule:DraftPlayersRule = new DraftPlayersRule(playerCfg);

        // make board config and generate board
        var boardCfg:BoardConfig = {circular:false, initGrid:initGrid};
        var buildBoardRule:BuildBoardRule = new BuildBoardRule(boardCfg);

        rules.unshift(buildBoardRule);
        rules.unshift(draftPlayersRule);

        return new StateFactory().makeState(rules, history);
	}
}
