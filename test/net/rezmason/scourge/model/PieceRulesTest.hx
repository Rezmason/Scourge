package net.rezmason.scourge.model;

import massive.munit.Assert;

import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.aspects.BodyAspect;
import net.rezmason.scourge.model.rules.DropPieceRule;
import net.rezmason.scourge.model.rules.TestPieceRule;
import net.rezmason.scourge.model.rules.PickPieceRule;

using net.rezmason.scourge.model.BoardUtils;
using net.rezmason.utils.Pointers;

class PieceRulesTest extends RuleTest
{
    private static var PIECE_SIZE:Int = 4;

	#if TIME_TESTS
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
    #end

    // An L/J block has nine neighbor cells.
    // Reflection allowed   rotation allowed    option count
    // N                    N                   9
    // Y                    N                   18
    // N                    Y                   36
    // Y                    Y                   72

	@Test
	public function placePieceRuleTest1():Void {

        var testPieceCfg:TestPieceConfig = {
            pieceID:Pieces.getPieceIdBySizeAndIndex(PIECE_SIZE, 1), // "L/J block"
            reflection:0,
            rotation:0,
        };
        var testPieceRule:TestPieceRule = new TestPieceRule(testPieceCfg);

        var dropConfig:DropPieceConfig = {overlapSelf:false, allowFlipping:true, allowRotating:true, growGraph:false};
        var dropRule:DropPieceRule = new DropPieceRule(dropConfig);
        makeState([testPieceRule, dropRule], 1, TestBoards.emptyPetri);

        dropRule.update();
        var options:Array<DropPieceOption> = cast dropRule.options;

        Assert.areEqual(72, options.length);

        var numCells:Int = ~/([^0])/g.replace(state.spitBoard(plan), "").length;
        Assert.areEqual(1, numCells); // 1 cell for player 0

        //trace(state.spitBoard(plan));
        dropRule.chooseOption(0);
        //trace(state.spitBoard(plan));

        numCells = ~/([^0])/g.replace(state.spitBoard(plan), "").length;
        Assert.areEqual(1 + PIECE_SIZE, numCells); // 5 cells for player 0

        var bodyFirst_:AspectPtr = plan.playerAspectLookup[BodyAspect.BODY_FIRST.id];
        var bodyNext_:AspectPtr = plan.nodeAspectLookup[BodyAspect.BODY_NEXT.id];
        var bodyPrev_:AspectPtr = plan.nodeAspectLookup[BodyAspect.BODY_PREV.id];
        var bodyNode:BoardNode = state.nodes[state.players[0].at(bodyFirst_)];

        Assert.areEqual(0, testListLength(numCells, bodyNode, bodyNext_, bodyPrev_));
	}

    @Test
    public function placePieceRuleTest2():Void {

        var testPieceCfg:TestPieceConfig = {
            pieceID:Pieces.getPieceIdBySizeAndIndex(PIECE_SIZE, 1), // "L/J block"
            reflection:0,
            rotation:0,
        };
        var testPieceRule:TestPieceRule = new TestPieceRule(testPieceCfg);

        var dropConfig:DropPieceConfig = {overlapSelf:false, allowFlipping:false, allowRotating:true, growGraph:false};
        var dropRule:DropPieceRule = new DropPieceRule(dropConfig);
        makeState([testPieceRule, dropRule], 1, TestBoards.emptyPetri);

        dropRule.update();
        var options:Array<DropPieceOption> = cast dropRule.options;

        Assert.areEqual(36, options.length);

        var numCells:Int = ~/([^0])/g.replace(state.spitBoard(plan), "").length;
        Assert.areEqual(1, numCells); // 1 cell for player 0

        //trace(state.spitBoard(plan));
        dropRule.chooseOption(0);
        //trace(state.spitBoard(plan));

        numCells = ~/([^0])/g.replace(state.spitBoard(plan), "").length;
        Assert.areEqual(1 + PIECE_SIZE, numCells); // 5 cells for player 0
    }

    @Test
    public function placePieceRuleTest3():Void {

        var testPieceCfg:TestPieceConfig = {
            pieceID:Pieces.getPieceIdBySizeAndIndex(PIECE_SIZE, 1), // "L/J block"
            reflection:0,
            rotation:0,
        };
        var testPieceRule:TestPieceRule = new TestPieceRule(testPieceCfg);

        var dropConfig:DropPieceConfig = {overlapSelf:false, allowFlipping:true, allowRotating:false, growGraph:false};
        var dropRule:DropPieceRule = new DropPieceRule(dropConfig);
        makeState([testPieceRule, dropRule], 1, TestBoards.emptyPetri);

        dropRule.update();
        var options:Array<DropPieceOption> = cast dropRule.options;

        Assert.areEqual(18, options.length);

        var numCells:Int = ~/([^0])/g.replace(state.spitBoard(plan), "").length;
        Assert.areEqual(1, numCells); // 1 cell for player 0

        //trace(state.spitBoard(plan));
        dropRule.chooseOption(0);
        //trace(state.spitBoard(plan));

        numCells = ~/([^0])/g.replace(state.spitBoard(plan), "").length;
        Assert.areEqual(1 + PIECE_SIZE, numCells); // 5 cells for player 0
    }

    @Test
    public function placePieceRuleTest4():Void {

        var testPieceCfg:TestPieceConfig = {
            pieceID:Pieces.getPieceIdBySizeAndIndex(PIECE_SIZE, 1), // "L/J block"
            reflection:0,
            rotation:0,
        };
        var testPieceRule:TestPieceRule = new TestPieceRule(testPieceCfg);

        var dropConfig:DropPieceConfig = {overlapSelf:false, allowFlipping:false, allowRotating:false, growGraph:false};
        var dropRule:DropPieceRule = new DropPieceRule(dropConfig);
        makeState([testPieceRule, dropRule], 1, TestBoards.emptyPetri);

        dropRule.update();
        var options:Array<DropPieceOption> = cast dropRule.options;

        Assert.areEqual(9, options.length);

        var numCells:Int = ~/([^0])/g.replace(state.spitBoard(plan), "").length;
        Assert.areEqual(1, numCells); // 1 cell for player 0

        //trace(state.spitBoard(plan));
        dropRule.chooseOption(0);
        //trace(state.spitBoard(plan));

        numCells = ~/([^0])/g.replace(state.spitBoard(plan), "").length;
        Assert.areEqual(1 + PIECE_SIZE, numCells); // 5 cells for player 0
    }

    @Test
    public function placePieceRuleTest5():Void {

        var testPieceCfg:TestPieceConfig = {
            pieceID:Pieces.getPieceIdBySizeAndIndex(PIECE_SIZE, 1), // "L/J block"
            reflection:0,
            rotation:0,
        };
        var testPieceRule:TestPieceRule = new TestPieceRule(testPieceCfg);

        var dropConfig:DropPieceConfig = {overlapSelf:true, allowFlipping:false, allowRotating:false, growGraph:false};
        var dropRule:DropPieceRule = new DropPieceRule(dropConfig);
        makeState([testPieceRule, dropRule], 1, TestBoards.emptyPetri);

        dropRule.update();
        var options:Array<DropPieceOption> = cast dropRule.options;

        Assert.areEqual(9 + 4, options.length);

        var numCells:Int = ~/([^0])/g.replace(state.spitBoard(plan), "").length;
        Assert.areEqual(1, numCells); // 1 cell for player 0

        //trace(state.spitBoard(plan));
        dropRule.chooseOption(0);
        //trace(state.spitBoard(plan));

        numCells = ~/([^0])/g.replace(state.spitBoard(plan), "").length;
        Assert.areEqual(1 + PIECE_SIZE, numCells); // 5 cells for player 0
    }

    @Test
    public function pickPieceTest():Void {
        var pickPieceCfg:PickPieceConfig = {
            history:history,
            historyState:historyState,
            pieceIDs:[0, 1, 2, 3, 4],
            allowFlipping:true,
            allowRotating:true,
            allowAll:false,
            hatSize:3,
        };
        var pickPieceRule:PickPieceRule = new PickPieceRule(pickPieceCfg);
        makeState(cast [pickPieceRule], 1, TestBoards.emptyPetri);

        pickPieceRule.update();
    }
}
