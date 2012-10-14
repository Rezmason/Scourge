package net.rezmason.scourge.model;

import massive.munit.Assert;

import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.Aspect;
import net.rezmason.scourge.model.aspects.BodyAspect;
import net.rezmason.scourge.model.aspects.PieceAspect;
import net.rezmason.scourge.model.rules.DropPieceRule;
import net.rezmason.scourge.model.rules.TestPieceRule;
import net.rezmason.scourge.model.rules.PickPieceRule;
import net.rezmason.scourge.model.rules.SwapPieceRule;

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
            pieceTableID:Pieces.getPieceIdBySizeAndIndex(PIECE_SIZE, 1), // "L/J block"
            reflection:0,
            rotation:0,
        };
        var testPieceRule:TestPieceRule = new TestPieceRule(testPieceCfg);

        var dropConfig:DropPieceConfig = {
            overlapSelf:false,
            allowFlipping:true,
            allowRotating:true,
            growGraph:false,
            allowNowhere:false,
        };
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
            pieceTableID:Pieces.getPieceIdBySizeAndIndex(PIECE_SIZE, 1), // "L/J block"
            reflection:0,
            rotation:0,
        };
        var testPieceRule:TestPieceRule = new TestPieceRule(testPieceCfg);

        var dropConfig:DropPieceConfig = {
            overlapSelf:false,
            allowFlipping:false,
            allowRotating:true,
            growGraph:false,
            allowNowhere:false,
        };
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
            pieceTableID:Pieces.getPieceIdBySizeAndIndex(PIECE_SIZE, 1), // "L/J block"
            reflection:0,
            rotation:0,
        };
        var testPieceRule:TestPieceRule = new TestPieceRule(testPieceCfg);

        var dropConfig:DropPieceConfig = {
            overlapSelf:false,
            allowFlipping:true,
            allowRotating:false,
            growGraph:false,
            allowNowhere:false,
        };
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
            pieceTableID:Pieces.getPieceIdBySizeAndIndex(PIECE_SIZE, 1), // "L/J block"
            reflection:0,
            rotation:0,
        };
        var testPieceRule:TestPieceRule = new TestPieceRule(testPieceCfg);

        var dropConfig:DropPieceConfig = {
            overlapSelf:false,
            allowFlipping:false,
            allowRotating:false,
            growGraph:false,
            allowNowhere:false,
        };
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
            pieceTableID:Pieces.getPieceIdBySizeAndIndex(PIECE_SIZE, 1), // "L/J block"
            reflection:0,
            rotation:0,
        };
        var testPieceRule:TestPieceRule = new TestPieceRule(testPieceCfg);

        var dropConfig:DropPieceConfig = {
            overlapSelf:true,
            allowFlipping:false,
            allowRotating:false,
            growGraph:false,
            allowNowhere:false,
        };
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
    public function placePieceRuleTest6():Void {

        var dropConfig:DropPieceConfig = {
            overlapSelf:false,
            allowFlipping:false,
            allowRotating:false,
            growGraph:false,
            allowNowhere:true,
        };
        var dropRule:DropPieceRule = new DropPieceRule(dropConfig);
        makeState([dropRule], 1, TestBoards.emptyPetri);

        dropRule.update();
        var options:Array<DropPieceOption> = cast dropRule.options;

        Assert.areEqual(1, options.length);

        var numCells:Int = ~/([^0])/g.replace(state.spitBoard(plan), "").length;
        Assert.areEqual(1, numCells); // 1 cell for player 0

        //trace(state.spitBoard(plan));
        dropRule.chooseOption(0);
        //trace(state.spitBoard(plan));

        numCells = ~/([^0])/g.replace(state.spitBoard(plan), "").length;
        Assert.areEqual(1, numCells); // 5 cells for player 0
    }

    @Test
    public function pickPieceTest():Void {

        var hatSize:Int = 3;
        var pieceTableIDs:Array<Int> = [0, 1, 2, 3, 4];
        var pickPieceCfg:PickPieceConfig = {
            history:history,
            historyState:historyState,
            pieceTableIDs:pieceTableIDs,
            allowFlipping:true,
            allowRotating:true,
            allowAll:false,
            hatSize:hatSize,
            randomFunction:function() return 0,
        };
        var pickPieceRule:PickPieceRule = new PickPieceRule(pickPieceCfg);
        makeState(cast [pickPieceRule], 1, TestBoards.emptyPetri);

        var pieceTableID_:AspectPtr = plan.stateAspectLookup[PieceAspect.PIECE_TABLE_ID.id];

        pickPieceRule.update();

        for (ike in 0...hatSize + 1) {
            Assert.areEqual(1, pickPieceRule.options.length);
            Assert.areEqual(pieceTableIDs.length - (ike % hatSize), pickPieceRule.quantumOptions.length);
            pickPieceRule.chooseOption(0);
            state.aspects.mod(pieceTableID_, Aspect.NULL);
            pickPieceRule.update();
        }
    }

    @Test
    public function pickPieceTestNoFlipping():Void {

        var hatSize:Int = 3;
        var pieceTableIDs:Array<Int> = [0, 1, 2, 3, 5]; // 5 is an L/J block
        var pickPieceCfg:PickPieceConfig = {
            history:history,
            historyState:historyState,
            pieceTableIDs:pieceTableIDs,
            allowFlipping:false,
            allowRotating:true,
            allowAll:false,
            hatSize:3,
            randomFunction:function() return 0,
        };
        var pickPieceRule:PickPieceRule = new PickPieceRule(pickPieceCfg);
        makeState(cast [pickPieceRule], 1, TestBoards.emptyPetri);

        var pieceTableID_:AspectPtr = plan.stateAspectLookup[PieceAspect.PIECE_TABLE_ID.id];

        pickPieceRule.update();

        Assert.areEqual(1, pickPieceRule.options.length);
        Assert.areEqual(6, pickPieceRule.quantumOptions.length);
    }

    @Test
    public function pickPieceTestNoSpinning():Void {

        var hatSize:Int = 3;
        var pieceTableIDs:Array<Int> = [0, 1, 2, 3, 4];
        var pickPieceCfg:PickPieceConfig = {
            history:history,
            historyState:historyState,
            pieceTableIDs:pieceTableIDs,
            allowFlipping:true,
            allowRotating:false,
            allowAll:false,
            hatSize:3,
            randomFunction:function() return 0,
        };
        var pickPieceRule:PickPieceRule = new PickPieceRule(pickPieceCfg);
        makeState(cast [pickPieceRule], 1, TestBoards.emptyPetri);

        var pieceTableID_:AspectPtr = plan.stateAspectLookup[PieceAspect.PIECE_TABLE_ID.id];

        pickPieceRule.update();

        Assert.areEqual(1, pickPieceRule.options.length);
        Assert.areEqual(11, pickPieceRule.quantumOptions.length);
    }

    @Test
    public function pickPieceTestFreePickins():Void {

        var hatSize:Int = 3;
        var pieceTableIDs:Array<Int> = [0, 1, 2, 3, 4];
        var pickPieceCfg:PickPieceConfig = {
            history:history,
            historyState:historyState,
            pieceTableIDs:pieceTableIDs,
            allowFlipping:true,
            allowRotating:true,
            allowAll:true,
            hatSize:3,
            randomFunction:function() return 0,
        };
        var pickPieceRule:PickPieceRule = new PickPieceRule(pickPieceCfg);
        makeState(cast [pickPieceRule], 1, TestBoards.emptyPetri);

        var pieceTableID_:AspectPtr = plan.stateAspectLookup[PieceAspect.PIECE_TABLE_ID.id];

        pickPieceRule.update();

        for (ike in 0...hatSize + 1) {
            Assert.areEqual(pieceTableIDs.length, pickPieceRule.options.length);
            pickPieceRule.chooseOption(0);
            state.aspects.mod(pieceTableID_, Aspect.NULL);
            pickPieceRule.update();
        }
    }

    @Test
    public function swapPieceTest():Void {
        var swapPieceCfg:SwapPieceConfig = {
            startingSwaps:5,
        };
        var swapPieceRule:SwapPieceRule = new SwapPieceRule(swapPieceCfg);
        makeState(cast [swapPieceRule], 1, TestBoards.emptyPetri);

        var pieceTableID_:AspectPtr = plan.stateAspectLookup[PieceAspect.PIECE_TABLE_ID.id];

        state.aspects.mod(pieceTableID_, 0);

        swapPieceRule.update();

        for (ike in 0...swapPieceCfg.startingSwaps) {
            Assert.areEqual(1, swapPieceRule.options.length);
            swapPieceRule.chooseOption(0);
            swapPieceRule.update();
            Assert.areEqual(0, swapPieceRule.options.length);
            state.aspects.mod(pieceTableID_, 0);
            swapPieceRule.update();
        }

        Assert.areEqual(0, swapPieceRule.options.length);
    }
}
