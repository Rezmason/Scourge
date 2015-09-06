package net.rezmason.scourge.game.bite;

import massive.munit.Assert;
import VisualAssert;

import net.rezmason.praxis.aspect.Aspect;
import net.rezmason.praxis.PraxisTypes;
import net.rezmason.scourge.game.bite.BiteAspect;
import net.rezmason.scourge.game.bite.BiteRule;
import net.rezmason.scourge.game.body.BodyAspect;
import net.rezmason.scourge.game.body.OwnershipAspect;
import net.rezmason.scourge.game.meta.FreshnessAspect;

using Lambda;
using net.rezmason.scourge.game.BoardUtils;
using net.rezmason.grid.GridUtils;
using net.rezmason.praxis.state.StatePlan;
using net.rezmason.utils.pointers.Pointers;

class BiteRuleTest extends ScourgeRuleTest
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
        trace('tick $time');
    }
    #end

    @Test
    public function straightBite1():Void {

        var biteParams:BiteParams = {
            startingBites:100,
            minReach:1,
            maxReach:1,
            maxSizeReference:1,
            baseReachOnThickness:false,
            omnidirectional:false,
            biteThroughCavities:false,
            biteHeads:false,
            orthoOnly:true,
        };
        var biteRule:BiteRule = new BiteRule(biteParams);
        makeState([biteRule], 2, TestBoards.twoPlayerBite);

        VisualAssert.assert('two player bite', state.spitBoard(plan));

        var totalArea_ = plan.onPlayer(BodyAspect.TOTAL_AREA);
        state.players[0][totalArea_] = ~/([^0])/g.replace(state.spitBoard(plan), '').length;

        biteRule.update();
        var moves:Array<BiteMove> = cast biteRule.moves;
        Assert.areEqual(9, moves.length);
        var numCells:Int = ~/([^1])/g.replace(state.spitBoard(plan), '').length;
        Assert.areEqual(20, numCells); // 20 cells for player 1
        biteRule.chooseMove();

        VisualAssert.assert('two player bite, bite taken up top', state.spitBoard(plan));

        numCells = ~/([^1])/g.replace(state.spitBoard(plan), '').length;
        Assert.areEqual(20 - 1, numCells); // 19 cells for player 1

        testEnemyBody(numCells);
    }

    @Test
    public function straightBite3():Void {

        var biteParams:BiteParams = {
            startingBites:100,
            minReach:1,
            maxReach:3,
            maxSizeReference:1,
            baseReachOnThickness:false,
            omnidirectional:false,
            biteThroughCavities:false,
            biteHeads:false,
            orthoOnly:true,
        };
        var biteRule:BiteRule = new BiteRule(biteParams);
        makeState([biteRule], 2, TestBoards.twoPlayerBite);

        VisualAssert.assert('two player bite', state.spitBoard(plan));

        var totalArea_ = plan.onPlayer(BodyAspect.TOTAL_AREA);
        state.players[0][totalArea_] = ~/([^0])/g.replace(state.spitBoard(plan), '').length;

        biteRule.update();
        var moves:Array<BiteMove> = cast biteRule.moves;
        Assert.areEqual(17, moves.length);
        var numCells:Int = ~/([^1])/g.replace(state.spitBoard(plan), '').length;
        Assert.areEqual(20, numCells); // 20 cells for player 1

        for (move in moves) {
            if (move.bitSpaces.length == biteParams.maxReach) {
                biteRule.chooseMove(move.id);
                break;
            }
        }

        VisualAssert.assert('two player bite, three-unit bite down from top', state.spitBoard(plan));

        numCells = ~/([^1])/g.replace(state.spitBoard(plan), '').length;
        Assert.areEqual(20 - biteParams.maxReach, numCells); // 19 cells for player 1

        testEnemyBody(numCells);
    }

    @Test
    public function diagonalStraightBite3():Void {

        var biteParams:BiteParams = {
            startingBites:100,
            minReach:1,
            maxReach:3,
            maxSizeReference:1,
            baseReachOnThickness:false,
            omnidirectional:false,
            biteThroughCavities:false,
            biteHeads:false,
            orthoOnly:false,
        };
        var biteRule:BiteRule = new BiteRule(biteParams);
        makeState([biteRule], 2, TestBoards.twoPlayerBite);

        VisualAssert.assert('two player bite', state.spitBoard(plan));

        var totalArea_ = plan.onPlayer(BodyAspect.TOTAL_AREA);
        state.players[0][totalArea_] = ~/([^0])/g.replace(state.spitBoard(plan), '').length;

        biteRule.update();
        var moves:Array<BiteMove> = cast biteRule.moves;
        Assert.areEqual(45, moves.length);
        var numCells:Int = ~/([^1])/g.replace(state.spitBoard(plan), '').length;
        Assert.areEqual(20, numCells); // 20 cells for player 1

        stateHistorian.write();

        for (move in moves) {
            if (move.bitSpaces.length == biteParams.maxReach) {
                biteRule.chooseMove(move.id);
                break;
            }
        }

        VisualAssert.assert('two player bite, three-unit bite down-diagonal from top', state.spitBoard(plan));

        numCells = ~/([^1])/g.replace(state.spitBoard(plan), '').length;
        Assert.areEqual(20 - biteParams.maxReach, numCells); // 19 cells for player 1

        testEnemyBody(numCells);
    }

    @Test
    public function omnidirectionalBite2():Void {

        var biteParams:BiteParams = {
            startingBites:100,
            minReach:1,
            maxReach:2,
            maxSizeReference:1,
            baseReachOnThickness:false,
            omnidirectional:true,
            biteThroughCavities:false,
            biteHeads:false,
            orthoOnly:true,
        };
        var biteRule:BiteRule = new BiteRule(biteParams);
        makeState([biteRule], 2, TestBoards.twoPlayerBite);

        VisualAssert.assert('two player bite', state.spitBoard(plan));

        var totalArea_ = plan.onPlayer(BodyAspect.TOTAL_AREA);
        state.players[0][totalArea_] = ~/([^0])/g.replace(state.spitBoard(plan), '').length;

        biteRule.update();
        var moves:Array<BiteMove> = cast biteRule.moves;
        Assert.areEqual(28, moves.length);
        var numCells:Int = ~/([^1])/g.replace(state.spitBoard(plan), '').length;
        Assert.areEqual(20, numCells); // 20 cells for player 1

        for (move in moves) {
            if (move.bitSpaces.length == biteParams.maxReach) {
                biteRule.chooseMove(move.id);
                break;
            }
        }

        VisualAssert.assert('two player bite, two-unit byte along top going east', state.spitBoard(plan));

        numCells = ~/([^1])/g.replace(state.spitBoard(plan), '').length;
        Assert.areEqual(20 - biteParams.maxReach, numCells); // 19 cells for player 1

        testEnemyBody(numCells);
    }

    @Test
    public function straightBiteThroughHeads():Void {

        var biteParams:BiteParams = {
            startingBites:100,
            minReach:1,
            maxReach:1,
            maxSizeReference:1,
            baseReachOnThickness:false,
            omnidirectional:false,
            biteThroughCavities:false,
            biteHeads:true,
            orthoOnly:true,
        };
        var biteRule:BiteRule = new BiteRule(biteParams);
        makeState([biteRule], 2, TestBoards.twoPlayerBite);

        var head_ = plan.onPlayer(BodyAspect.HEAD);
        var enemyHeadID:Int = state.players[1][head_];

        VisualAssert.assert('two player bite', state.spitBoard(plan));

        var totalArea_ = plan.onPlayer(BodyAspect.TOTAL_AREA);
        state.players[0][totalArea_] = ~/([^0])/g.replace(state.spitBoard(plan), '').length;

        biteRule.update();
        var moves:Array<BiteMove> = cast biteRule.moves;
        Assert.areEqual(10, moves.length);
        var numCells:Int = ~/([^1])/g.replace(state.spitBoard(plan), '').length;
        Assert.areEqual(20, numCells); // 20 cells for player 1

        for (move in moves) {
            if (move.bitSpaces.has(enemyHeadID)) {
                biteRule.chooseMove(move.id);
                break;
            }
        }
        VisualAssert.assert('two player bite, player one\'s noggin bit', state.spitBoard(plan));


        numCells = ~/([^1])/g.replace(state.spitBoard(plan), '').length;
        Assert.areEqual(20 - 1, numCells); // 19 cells for player 1

        testEnemyBody(numCells);
    }

    @Test
    public function straightBiteBasedOnThickness():Void {

        var biteParams:BiteParams = {
            startingBites:100,
            minReach:1,
            maxReach:20,
            maxSizeReference:1,
            baseReachOnThickness:true,
            omnidirectional:false,
            biteThroughCavities:false,
            biteHeads:true,
            orthoOnly:true,
        };

        var biteRule:BiteRule = new BiteRule(biteParams);
        makeState([biteRule], 2, TestBoards.twoPlayerBite);

        VisualAssert.assert('two player bite', state.spitBoard(plan));

        var totalArea_ = plan.onPlayer(BodyAspect.TOTAL_AREA);
        state.players[0][totalArea_] = ~/([^0])/g.replace(state.spitBoard(plan), '').length;

        biteRule.update();
        var moves:Array<BiteMove> = cast biteRule.moves;
        Assert.areEqual(20, moves.length);
        var numCells:Int = ~/([^1])/g.replace(state.spitBoard(plan), '').length;
        Assert.areEqual(20, numCells); // 20 cells for player 1
        var numBitSpaces:Int = 0;
        var thickestMoveID:Int = -1;
        for (move in moves) {
            if (numBitSpaces < move.bitSpaces.length) {
                numBitSpaces = move.bitSpaces.length;
                thickestMoveID = move.id;
            }
        }
        biteRule.chooseMove(thickestMoveID);

        VisualAssert.assert('two player bite, deep bite right through the middle', state.spitBoard(plan));

        numCells = ~/([^1])/g.replace(state.spitBoard(plan), '').length;
        Assert.areEqual(20 - numBitSpaces, numCells); // 19 cells for player 1

        testEnemyBody(numCells);
    }

    @Test
    public function cavityBite():Void {

        var biteParams:BiteParams = {
            startingBites:100,
            minReach:1,
            maxReach:2,
            maxSizeReference:1,
            baseReachOnThickness:false,
            omnidirectional:false,
            biteThroughCavities:true,
            biteHeads:false,
            orthoOnly:true,
        };
        var biteRule:BiteRule = new BiteRule(biteParams);
        makeState([biteRule], 2, TestBoards.twoPlayerBite);

        var head_ = plan.onPlayer(BodyAspect.HEAD);
        var occupier_ = plan.onSpace(OwnershipAspect.OCCUPIER);
        var enemyHeadID:Int = state.players[1][head_];
        var enemyHead:BoardCell = state.cells.getCell(enemyHeadID);
        var cavity:BoardCell = enemyHead.s().s().e();
        cavity.value[occupier_] = 1;

        VisualAssert.assert('two player bite with small cavity in player one', state.spitBoard(plan));

        var totalArea_ = plan.onPlayer(BodyAspect.TOTAL_AREA);
        state.players[0][totalArea_] = ~/([^0])/g.replace(state.spitBoard(plan), '').length;

        biteRule.update();
        var moves:Array<BiteMove> = cast biteRule.moves;
        Assert.areEqual(9 + 6, moves.length);
        var numCells:Int = ~/([^1])/g.replace(state.spitBoard(plan), '').length;
        Assert.areEqual(20, numCells); // 20 cells for player 1

        var cavityID:Int = getID(cavity.value);
        for (move in moves) {
            if (move.bitSpaces.has(cavityID)) {
                biteRule.chooseMove(move.id);
                break;
            }
        }

        VisualAssert.assert('two player bite, cavity bitten', state.spitBoard(plan));

        numCells = ~/([^1])/g.replace(state.spitBoard(plan), '').length;
        Assert.areEqual(20 - 1, numCells); // 19 cells for player 1

        testEnemyBody(numCells);
    }

    private function testEnemyBody(expectedSize:Int):Void {
        var bodyFirst_ = plan.onPlayer(BodyAspect.BODY_FIRST);
        var bodyNext_ = plan.onSpace(BodyAspect.BODY_NEXT);
        var bodyPrev_ = plan.onSpace(BodyAspect.BODY_PREV);
        var bodySpace = state.spaces[state.players[1][bodyFirst_]];

        Assert.areEqual(0, testListLength(expectedSize, bodySpace, bodyNext_, bodyPrev_));
    }
}
