package net.rezmason.scourge.model;

import massive.munit.Assert;
import VisualAssert;

import net.rezmason.ropes.RopesTypes;
import net.rezmason.ropes.Aspect;
import net.rezmason.scourge.model.aspects.BodyAspect;
import net.rezmason.scourge.model.aspects.FreshnessAspect;
import net.rezmason.scourge.model.aspects.PieceAspect;
import net.rezmason.scourge.model.rules.DropPieceRule;
import net.rezmason.scourge.model.rules.TestPieceRule;
import net.rezmason.scourge.model.rules.PickPieceRule;
import net.rezmason.scourge.model.rules.SwapPieceRule;
import net.rezmason.scourge.tools.Resource;

using net.rezmason.scourge.model.BoardUtils;
using net.rezmason.ropes.StatePlan;
using net.rezmason.utils.Pointers;

class PieceRulesTest extends ScourgeRuleTest
{
    private static var PIECE_SIZE:Int = 4;

    #if TIME_TESTS
    var time:Float;
    #end
    var pieces:Pieces;

    @Before
    public function setup():Void {
        #if TIME_TESTS
        time = massive.munit.util.Timer.stamp();
        #end
        pieces = new Pieces(Resource.getString('tables/pieces.json.txt'));
    }

    @After
    public function tearDown():Void {
        #if TIME_TESTS
        time = massive.munit.util.Timer.stamp() - time;
        trace('tick $time');
        #end
    }

    // An L/J block has nine neighbor cells.
    // Reflection allowed   rotation allowed    move count
    // N                    N                   9
    // Y                    N                   18
    // N                    Y                   36
    // Y                    Y                   72

    @Test
    public function placePieceScourgeRuleTestOrtho():Void {

        var testPieceCfg:TestPieceConfig = {
            pieceTableID:pieces.getPieceIdBySizeAndIndex(PIECE_SIZE, 1), // 'L/J block'
            reflection:0,
            rotation:0,
        };
        var testPieceRule:TestPieceRule = new TestPieceRule();
        testPieceRule.init(testPieceCfg);

        var dropConfig:DropPieceConfig = {
            overlapSelf:false,
            allowFlipping:true,
            allowRotating:true,
            growGraph:false,
            allowNowhere:false,
            orthoOnly:true,
            diagOnly:false,
            pieces:pieces,
            pieceTableIDs:pieces.getAllPieceIDsOfSize(4),
            allowPiecePick:false,
        };
        var dropRule:DropPieceRule = new DropPieceRule();
        dropRule.init(dropConfig);
        makeState([testPieceRule, dropRule], 1, TestBoards.emptyPetri);

        dropRule.update();
        var moves:Array<DropPieceMove> = cast dropRule.moves;

        Assert.areEqual(72, moves.length);

        var numCells:Int = ~/([^0])/g.replace(state.spitBoard(plan), '').length;
        Assert.areEqual(1, numCells); // 1 cell for player 0

        VisualAssert.assert('empty petri', state.spitBoard(plan));

        dropRule.chooseMove();

        VisualAssert.assert('empty petri, L piece on top left extending up', state.spitBoard(plan));

        numCells = ~/([^0])/g.replace(state.spitBoard(plan), '').length;
        Assert.areEqual(1 + PIECE_SIZE, numCells); // 5 cells for player 0

        var bodyFirst_:AspectPtr = plan.onPlayer(BodyAspect.BODY_FIRST);
        var bodyNext_:AspectPtr = plan.onNode(BodyAspect.BODY_NEXT);
        var bodyPrev_:AspectPtr = plan.onNode(BodyAspect.BODY_PREV);
        var bodyNode:AspectSet = state.nodes[state.players[0][bodyFirst_]];

        Assert.areEqual(0, testListLength(numCells, bodyNode, bodyNext_, bodyPrev_));
    }

    @Test
    public function placePieceScourgeRuleTestOrthoNoSpace():Void {

        var testPieceCfg:TestPieceConfig = {
            pieceTableID:pieces.getPieceIdBySizeAndIndex(PIECE_SIZE, 0), // 'L/J block'
            reflection:0,
            rotation:0,
        };

        var testPieceRule:TestPieceRule = new TestPieceRule();
        testPieceRule.init(testPieceCfg);

        var dropConfig:DropPieceConfig = {
            overlapSelf:false,
            allowFlipping:true,
            allowRotating:true,
            growGraph:false,
            allowNowhere:false,
            orthoOnly:true,
            diagOnly:false,
            pieces:pieces,
            pieceTableIDs:pieces.getAllPieceIDsOfSize(4),
            allowPiecePick:false,
        };
        var dropRule:DropPieceRule = new DropPieceRule();
        dropRule.init(dropConfig);
        makeState([testPieceRule, dropRule], 1, TestBoards.frozenPetri);

        dropRule.update();
        var moves:Array<DropPieceMove> = cast dropRule.moves;

        Assert.areEqual(0, moves.length); // The board has no room for the piece! There should be no moves.

        var numWalls:Int = ~/([^X])/g.replace(state.spitBoard(plan), '').length;
        Assert.areEqual(160, numWalls); // 160 walls cells

        VisualAssert.assert('full petri', state.spitBoard(plan));
    }

    @Test
    public function placePieceScourgeRuleTestOrthoNoFlipping():Void {

        var testPieceCfg:TestPieceConfig = {
            pieceTableID:pieces.getPieceIdBySizeAndIndex(PIECE_SIZE, 1), // 'L/J block'
            reflection:0,
            rotation:0,
        };
        var testPieceRule:TestPieceRule = new TestPieceRule();
        testPieceRule.init(testPieceCfg);

        var dropConfig:DropPieceConfig = {
            overlapSelf:false,
            allowFlipping:false,
            allowRotating:true,
            growGraph:false,
            allowNowhere:false,
            orthoOnly:true,
            diagOnly:false,
            pieces:pieces,
            pieceTableIDs:pieces.getAllPieceIDsOfSize(4),
            allowPiecePick:false,
        };
        var dropRule:DropPieceRule = new DropPieceRule();
        dropRule.init(dropConfig);
        makeState([testPieceRule, dropRule], 1, TestBoards.emptyPetri);

        dropRule.update();
        var moves:Array<DropPieceMove> = cast dropRule.moves;

        Assert.areEqual(36, moves.length);

        var numCells:Int = ~/([^0])/g.replace(state.spitBoard(plan), '').length;
        Assert.areEqual(1, numCells); // 1 cell for player 0

        dropRule.chooseMove();

        numCells = ~/([^0])/g.replace(state.spitBoard(plan), '').length;
        Assert.areEqual(1 + PIECE_SIZE, numCells); // 5 cells for player 0
    }

    @Test
    public function placePieceScourgeRuleTestOrthoNoSpinning():Void {

        var testPieceCfg:TestPieceConfig = {
            pieceTableID:pieces.getPieceIdBySizeAndIndex(PIECE_SIZE, 1), // 'L/J block'
            reflection:0,
            rotation:0,
        };
        var testPieceRule:TestPieceRule = new TestPieceRule();
        testPieceRule.init(testPieceCfg);

        var dropConfig:DropPieceConfig = {
            overlapSelf:false,
            allowFlipping:true,
            allowRotating:false,
            growGraph:false,
            allowNowhere:false,
            orthoOnly:true,
            diagOnly:false,
            pieces:pieces,
            pieceTableIDs:pieces.getAllPieceIDsOfSize(4),
            allowPiecePick:false,
        };
        var dropRule:DropPieceRule = new DropPieceRule();
        dropRule.init(dropConfig);
        makeState([testPieceRule, dropRule], 1, TestBoards.emptyPetri);

        dropRule.update();
        var moves:Array<DropPieceMove> = cast dropRule.moves;

        Assert.areEqual(18, moves.length);

        var numCells:Int = ~/([^0])/g.replace(state.spitBoard(plan), '').length;
        Assert.areEqual(1, numCells); // 1 cell for player 0

        dropRule.chooseMove();

        numCells = ~/([^0])/g.replace(state.spitBoard(plan), '').length;
        Assert.areEqual(1 + PIECE_SIZE, numCells); // 5 cells for player 0
    }

    @Test
    public function placePieceScourgeRuleTestOrthoNoSpinningOrFlipping():Void {

        var testPieceCfg:TestPieceConfig = {
            pieceTableID:pieces.getPieceIdBySizeAndIndex(PIECE_SIZE, 1), // 'L/J block'
            reflection:0,
            rotation:0,
        };
        var testPieceRule:TestPieceRule = new TestPieceRule();
        testPieceRule.init(testPieceCfg);

        var dropConfig:DropPieceConfig = {
            overlapSelf:false,
            allowFlipping:false,
            allowRotating:false,
            growGraph:false,
            allowNowhere:false,
            orthoOnly:true,
            diagOnly:false,
            pieces:pieces,
            pieceTableIDs:pieces.getAllPieceIDsOfSize(4),
            allowPiecePick:false,
        };
        var dropRule:DropPieceRule = new DropPieceRule();
        dropRule.init(dropConfig);
        makeState([testPieceRule, dropRule], 1, TestBoards.emptyPetri);

        dropRule.update();
        var moves:Array<DropPieceMove> = cast dropRule.moves;

        Assert.areEqual(9, moves.length);

        var numCells:Int = ~/([^0])/g.replace(state.spitBoard(plan), '').length;
        Assert.areEqual(1, numCells); // 1 cell for player 0

        dropRule.chooseMove();

        numCells = ~/([^0])/g.replace(state.spitBoard(plan), '').length;
        Assert.areEqual(1 + PIECE_SIZE, numCells); // 5 cells for player 0
    }

    @Test
    public function placePieceScourgeRuleTestOrthoSelf():Void {

        var testPieceCfg:TestPieceConfig = {
            pieceTableID:pieces.getPieceIdBySizeAndIndex(PIECE_SIZE, 1), // 'L/J block'
            reflection:0,
            rotation:0,
        };
        var testPieceRule:TestPieceRule = new TestPieceRule();
        testPieceRule.init(testPieceCfg);

        var dropConfig:DropPieceConfig = {
            overlapSelf:true,
            allowFlipping:false,
            allowRotating:false,
            growGraph:false,
            allowNowhere:false,
            orthoOnly:true,
            diagOnly:false,
            pieces:pieces,
            pieceTableIDs:pieces.getAllPieceIDsOfSize(4),
            allowPiecePick:false,
        };
        var dropRule:DropPieceRule = new DropPieceRule();
        dropRule.init(dropConfig);
        makeState([testPieceRule, dropRule], 1, TestBoards.emptyPetri);

        dropRule.update();
        var moves:Array<DropPieceMove> = cast dropRule.moves;

        Assert.areEqual(9 + 4, moves.length);

        var numCells:Int = ~/([^0])/g.replace(state.spitBoard(plan), '').length;
        Assert.areEqual(1, numCells); // 1 cell for player 0

        dropRule.chooseMove();

        numCells = ~/([^0])/g.replace(state.spitBoard(plan), '').length;
        Assert.areEqual(PIECE_SIZE, numCells); // 5 cells for player 0
    }

    @Test
    public function placePieceScourgeRuleTestOrthoAllowNowhere():Void {

        var dropConfig:DropPieceConfig = {
            overlapSelf:false,
            allowFlipping:false,
            allowRotating:false,
            growGraph:false,
            allowNowhere:true,
            orthoOnly:true,
            diagOnly:false,
            pieces:pieces,
            pieceTableIDs:pieces.getAllPieceIDsOfSize(4),
            allowPiecePick:false,
        };
        var dropRule:DropPieceRule = new DropPieceRule();
        dropRule.init(dropConfig);
        makeState([dropRule], 1, TestBoards.emptyPetri);

        dropRule.update();
        var moves:Array<DropPieceMove> = cast dropRule.moves;

        Assert.areEqual(1, moves.length);

        var numCells:Int = ~/([^0])/g.replace(state.spitBoard(plan), '').length;
        Assert.areEqual(1, numCells); // 1 cell for player 0

        VisualAssert.assert('empty petri', state.spitBoard(plan));

        dropRule.chooseMove();

        VisualAssert.assert('empty petri', state.spitBoard(plan));

        numCells = ~/([^0])/g.replace(state.spitBoard(plan), '').length;
        Assert.areEqual(1, numCells); // 1 cell still for player 0
    }

    @Test
    public function pickPieceTest():Void {

        var hatSize:Int = 3;
        var pieceTableIDs:Array<Int> = [0, 1, 2, 3, 4];
        var pickPieceCfg:PickPieceConfig = {
            pieceTableIDs:pieceTableIDs,
            allowFlipping:true,
            allowRotating:true,
            hatSize:hatSize,
            randomFunction:function() return 0,
            pieces:pieces,
        };
        var pickPieceRule:PickPieceRule = new PickPieceRule();
        pickPieceRule.init(pickPieceCfg);
        makeState([pickPieceRule], 1, TestBoards.emptyPetri);

        var pieceTableID_:AspectPtr = plan.onState(PieceAspect.PIECE_TABLE_ID);

        pickPieceRule.update();

        for (ike in 0...hatSize * 2) {
            Assert.areEqual(1, pickPieceRule.moves.length);
            Assert.areEqual(pieceTableIDs.length - (ike % hatSize), pickPieceRule.quantumMoves.length);
            pickPieceRule.chooseMove();
            Assert.areEqual(pieceTableIDs[ike % hatSize], state.globals[pieceTableID_]);
            state.globals[pieceTableID_] =  Aspect.NULL;
            pickPieceRule.update();
        }
    }

    @Test
    public function pickPieceTestNoFlipping():Void {

        var hatSize:Int = 3;
        var pieceTableIDs:Array<Int> = [0, 1, 2, 3, 5]; // 5 is an L/J block
        var pickPieceCfg:PickPieceConfig = {
            pieceTableIDs:pieceTableIDs,
            allowFlipping:false,
            allowRotating:true,
            hatSize:3,
            randomFunction:function() return 0,
            pieces:pieces,
        };
        var pickPieceRule:PickPieceRule = new PickPieceRule();
        pickPieceRule.init(pickPieceCfg);
        makeState([pickPieceRule], 1, TestBoards.emptyPetri);

        var pieceTableID_:AspectPtr = plan.onState(PieceAspect.PIECE_TABLE_ID);

        pickPieceRule.update();

        Assert.areEqual(1, pickPieceRule.moves.length);
        Assert.areEqual(6, pickPieceRule.quantumMoves.length);
    }

    @Test
    public function pickPieceTestNoSpinning():Void {

        var hatSize:Int = 3;
        var pieceTableIDs:Array<Int> = [0, 1, 2, 3, 4];
        var pickPieceCfg:PickPieceConfig = {
            pieceTableIDs:pieceTableIDs,
            allowFlipping:true,
            allowRotating:false,
            hatSize:3,
            randomFunction:function() return 0,
            pieces:pieces,
        };
        var pickPieceRule:PickPieceRule = new PickPieceRule();
        pickPieceRule.init(pickPieceCfg);
        makeState([pickPieceRule], 1, TestBoards.emptyPetri);

        var pieceTableID_:AspectPtr = plan.onState(PieceAspect.PIECE_TABLE_ID);

        pickPieceRule.update();

        Assert.areEqual(1, pickPieceRule.moves.length);
        Assert.areEqual(11, pickPieceRule.quantumMoves.length);
    }

    @Test
    public function placePieceScourgeRuleTestDiag():Void {

        var testPieceCfg:TestPieceConfig = {
            pieceTableID:pieces.getPieceIdBySizeAndIndex(PIECE_SIZE, 1), // 'L/J block'
            reflection:0,
            rotation:0,
        };
        var testPieceRule:TestPieceRule = new TestPieceRule();
        testPieceRule.init(testPieceCfg);

        var dropConfig:DropPieceConfig = {
            overlapSelf:false,
            allowFlipping:true,
            allowRotating:true,
            growGraph:false,
            allowNowhere:false,
            orthoOnly:false,
            diagOnly:true,
            pieces:pieces,
            pieceTableIDs:pieces.getAllPieceIDsOfSize(4),
            allowPiecePick:false,
        };
        var dropRule:DropPieceRule = new DropPieceRule();
        dropRule.init(dropConfig);
        makeState([testPieceRule, dropRule], 1, TestBoards.emptyPetri);

        dropRule.update();
        var moves:Array<DropPieceMove> = cast dropRule.moves;

        Assert.areEqual(40, moves.length);

        var numCells:Int = ~/([^0])/g.replace(state.spitBoard(plan), '').length;
        Assert.areEqual(1, numCells); // 1 cell for player 0

        dropRule.chooseMove();

        numCells = ~/([^0])/g.replace(state.spitBoard(plan), '').length;
        Assert.areEqual(1 + PIECE_SIZE, numCells); // 5 cells for player 0
    }

    @Test
    public function placePieceScourgeRuleTestOrthoDiag():Void {

        var testPieceCfg:TestPieceConfig = {
            pieceTableID:pieces.getPieceIdBySizeAndIndex(PIECE_SIZE, 1), // 'L/J block'
            reflection:0,
            rotation:0,
        };

        var testPieceRule:TestPieceRule = new TestPieceRule();
        testPieceRule.init(testPieceCfg);

        var dropConfig:DropPieceConfig = {
            overlapSelf:false,
            allowFlipping:false,
            allowRotating:false,
            growGraph:false,
            allowNowhere:false,
            orthoOnly:false,
            diagOnly:false,
            pieces:pieces,
            pieceTableIDs:pieces.getAllPieceIDsOfSize(4),
            allowPiecePick:false,
        };
        var dropRule:DropPieceRule = new DropPieceRule();
        dropRule.init(dropConfig);
        makeState([testPieceRule, dropRule], 1, TestBoards.flowerPetri);

        dropRule.update();
        var moves:Array<DropPieceMove> = cast dropRule.moves;

        Assert.areEqual(33, moves.length);

        var numCells:Int = ~/([^0])/g.replace(state.spitBoard(plan), '').length;
        Assert.areEqual(5, numCells); // 5 cells for player 0

        dropRule.chooseMove();

        numCells = ~/([^0])/g.replace(state.spitBoard(plan), '').length;
        Assert.areEqual(5 + 4, numCells); // 9 cells for player 0
    }

    @Test
    public function swapPieceTest():Void {
        var swapPieceCfg:SwapPieceConfig = {
            startingSwaps:5,
        };
        var swapPieceRule:SwapPieceRule = new SwapPieceRule();
        swapPieceRule.init(swapPieceCfg);
        makeState([swapPieceRule], 1, TestBoards.emptyPetri);

        var pieceTableID_:AspectPtr = plan.onState(PieceAspect.PIECE_TABLE_ID);

        state.globals[pieceTableID_] =  0;

        swapPieceRule.update();

        for (ike in 0...swapPieceCfg.startingSwaps) {
            Assert.areEqual(1, swapPieceRule.moves.length);
            swapPieceRule.chooseMove();
            swapPieceRule.update();
            Assert.areEqual(0, swapPieceRule.moves.length);
            state.globals[pieceTableID_] =  0;
            swapPieceRule.update();
        }

        Assert.areEqual(0, swapPieceRule.moves.length);
    }
}
