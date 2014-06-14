package net.rezmason.scourge.model;

import massive.munit.Assert;
import VisualAssert;

import net.rezmason.ropes.Aspect;
import net.rezmason.ropes.RopesTypes;
import net.rezmason.scourge.model.aspects.BiteAspect;
import net.rezmason.scourge.model.aspects.BodyAspect;
import net.rezmason.scourge.model.aspects.FreshnessAspect;
import net.rezmason.scourge.model.aspects.OwnershipAspect;
import net.rezmason.scourge.model.rules.BiteRule;

using Lambda;
using net.rezmason.scourge.model.BoardUtils;
using net.rezmason.ropes.GridUtils;
using net.rezmason.ropes.StatePlan;
using net.rezmason.utils.Pointers;

class BiteRuleTest extends ScourgeRuleTest
{
    private static var PIECE_SIZE:Int = 4;
    private static var freshnessBoardMod:Map<String, String> = [FreshnessAspect.FRESHNESS.id=>'F'];

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

        var biteConfig:BiteConfig = {
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
        var biteRule:BiteRule = new BiteRule();
        biteRule.init(biteConfig);
        makeState([biteRule], 2, TestBoards.twoPlayerBite);

        VisualAssert.assert('two player bite', state.spitBoard(plan, true, freshnessBoardMod));

        var totalArea_:AspectPtr = plan.onPlayer(BodyAspect.TOTAL_AREA);
        state.players[0][totalArea_] = ~/([^0])/g.replace(state.spitBoard(plan), '').length;

        biteRule.update();
        var moves:Array<BiteMove> = cast biteRule.moves;
        Assert.areEqual(9, moves.length);
        var numCells:Int = ~/([^1])/g.replace(state.spitBoard(plan), '').length;
        Assert.areEqual(20, numCells); // 20 cells for player 1
        biteRule.chooseMove();

        VisualAssert.assert('two player bite, bite taken up top', state.spitBoard(plan, true, freshnessBoardMod));

        numCells = ~/([^1])/g.replace(state.spitBoard(plan), '').length;
        Assert.areEqual(20 - 1, numCells); // 19 cells for player 1

        testEnemyBody(numCells);
    }

    @Test
    public function straightBite3():Void {

        var biteConfig:BiteConfig = {
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
        var biteRule:BiteRule = new BiteRule();
        biteRule.init(biteConfig);
        makeState([biteRule], 2, TestBoards.twoPlayerBite);

        VisualAssert.assert('two player bite', state.spitBoard(plan, true, freshnessBoardMod));

        var totalArea_:AspectPtr = plan.onPlayer(BodyAspect.TOTAL_AREA);
        state.players[0][totalArea_] = ~/([^0])/g.replace(state.spitBoard(plan), '').length;

        biteRule.update();
        var moves:Array<BiteMove> = cast biteRule.moves;
        Assert.areEqual(17, moves.length);
        var numCells:Int = ~/([^1])/g.replace(state.spitBoard(plan), '').length;
        Assert.areEqual(20, numCells); // 20 cells for player 1

        for (move in moves) {
            if (move.bitNodes.length == biteConfig.maxReach) {
                biteRule.chooseMove(move.id);
                break;
            }
        }

        VisualAssert.assert('two player bite, three-unit bite down from top', state.spitBoard(plan, true, freshnessBoardMod));

        numCells = ~/([^1])/g.replace(state.spitBoard(plan), '').length;
        Assert.areEqual(20 - biteConfig.maxReach, numCells); // 19 cells for player 1

        testEnemyBody(numCells);
    }

    @Test
    public function diagonalStraightBite3():Void {

        var biteConfig:BiteConfig = {
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
        var biteRule:BiteRule = new BiteRule();
        biteRule.init(biteConfig);
        makeState([biteRule], 2, TestBoards.twoPlayerBite);

        VisualAssert.assert('two player bite', state.spitBoard(plan, true, freshnessBoardMod));

        var totalArea_:AspectPtr = plan.onPlayer(BodyAspect.TOTAL_AREA);
        state.players[0][totalArea_] = ~/([^0])/g.replace(state.spitBoard(plan), '').length;

        biteRule.update();
        var moves:Array<BiteMove> = cast biteRule.moves;
        Assert.areEqual(45, moves.length);
        var numCells:Int = ~/([^1])/g.replace(state.spitBoard(plan), '').length;
        Assert.areEqual(20, numCells); // 20 cells for player 1

        stateHistorian.write();

        for (move in moves) {
            if (move.bitNodes.length == biteConfig.maxReach) {
                biteRule.chooseMove(move.id);
                break;
            }
        }

        VisualAssert.assert('two player bite, three-unit bite down-diagonal from top', state.spitBoard(plan, true, freshnessBoardMod));

        numCells = ~/([^1])/g.replace(state.spitBoard(plan), '').length;
        Assert.areEqual(20 - biteConfig.maxReach, numCells); // 19 cells for player 1

        testEnemyBody(numCells);
    }

    @Test
    public function omnidirectionalBite2():Void {

        var biteConfig:BiteConfig = {
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
        var biteRule:BiteRule = new BiteRule();
        biteRule.init(biteConfig);
        makeState([biteRule], 2, TestBoards.twoPlayerBite);

        VisualAssert.assert('two player bite', state.spitBoard(plan, true, freshnessBoardMod));

        var totalArea_:AspectPtr = plan.onPlayer(BodyAspect.TOTAL_AREA);
        state.players[0][totalArea_] = ~/([^0])/g.replace(state.spitBoard(plan), '').length;

        biteRule.update();
        var moves:Array<BiteMove> = cast biteRule.moves;
        Assert.areEqual(28, moves.length);
        var numCells:Int = ~/([^1])/g.replace(state.spitBoard(plan), '').length;
        Assert.areEqual(20, numCells); // 20 cells for player 1

        for (move in moves) {
            if (move.bitNodes.length == biteConfig.maxReach) {
                biteRule.chooseMove(move.id);
                break;
            }
        }

        VisualAssert.assert('two player bite, two-unit byte along top going east', state.spitBoard(plan, true, freshnessBoardMod));

        numCells = ~/([^1])/g.replace(state.spitBoard(plan), '').length;
        Assert.areEqual(20 - biteConfig.maxReach, numCells); // 19 cells for player 1

        testEnemyBody(numCells);
    }

    @Test
    public function straightBiteThroughHeads():Void {

        var biteConfig:BiteConfig = {
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
        var biteRule:BiteRule = new BiteRule();
        biteRule.init(biteConfig);
        makeState([biteRule], 2, TestBoards.twoPlayerBite);

        var head_:AspectPtr = plan.onPlayer(BodyAspect.HEAD);
        var enemyHeadID:Int = state.players[1][head_];

        VisualAssert.assert('two player bite', state.spitBoard(plan, true, freshnessBoardMod));

        var totalArea_:AspectPtr = plan.onPlayer(BodyAspect.TOTAL_AREA);
        state.players[0][totalArea_] = ~/([^0])/g.replace(state.spitBoard(plan), '').length;

        biteRule.update();
        var moves:Array<BiteMove> = cast biteRule.moves;
        Assert.areEqual(10, moves.length);
        var numCells:Int = ~/([^1])/g.replace(state.spitBoard(plan), '').length;
        Assert.areEqual(20, numCells); // 20 cells for player 1

        for (move in moves) {
            if (move.bitNodes.has(enemyHeadID)) {
                biteRule.chooseMove(move.id);
                break;
            }
        }
        VisualAssert.assert('two player bite, player one\'s noggin bit', state.spitBoard(plan, true, freshnessBoardMod));


        numCells = ~/([^1])/g.replace(state.spitBoard(plan), '').length;
        Assert.areEqual(20 - 1, numCells); // 19 cells for player 1

        testEnemyBody(numCells);
    }

    @Test
    public function straightBiteBasedOnThickness():Void {

        var biteConfig:BiteConfig = {
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

        var biteRule:BiteRule = new BiteRule();
        biteRule.init(biteConfig);
        makeState([biteRule], 2, TestBoards.twoPlayerBite);

        VisualAssert.assert('two player bite', state.spitBoard(plan, true, freshnessBoardMod));

        var totalArea_:AspectPtr = plan.onPlayer(BodyAspect.TOTAL_AREA);
        state.players[0][totalArea_] = ~/([^0])/g.replace(state.spitBoard(plan), '').length;

        biteRule.update();
        var moves:Array<BiteMove> = cast biteRule.moves;
        Assert.areEqual(20, moves.length);
        var numCells:Int = ~/([^1])/g.replace(state.spitBoard(plan), '').length;
        Assert.areEqual(20, numCells); // 20 cells for player 1
        var numBitNodes:Int = 0;
        var thickestMoveID:Int = -1;
        for (move in moves) {
            if (numBitNodes < move.bitNodes.length) {
                numBitNodes = move.bitNodes.length;
                thickestMoveID = move.id;
            }
        }
        biteRule.chooseMove(thickestMoveID);

        VisualAssert.assert('two player bite, deep bite right through the middle', state.spitBoard(plan, true, freshnessBoardMod));

        numCells = ~/([^1])/g.replace(state.spitBoard(plan), '').length;
        Assert.areEqual(20 - numBitNodes, numCells); // 19 cells for player 1

        testEnemyBody(numCells);
    }

    @Test
    public function cavityBite():Void {

        var biteConfig:BiteConfig = {
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
        var biteRule:BiteRule = new BiteRule();
        biteRule.init(biteConfig);
        makeState([biteRule], 2, TestBoards.twoPlayerBite);

        var head_:AspectPtr = plan.onPlayer(BodyAspect.HEAD);
        var occupier_:AspectPtr = plan.onNode(OwnershipAspect.OCCUPIER);
        var enemyHeadID:Int = state.players[1][head_];
        var enemyHead:BoardLocus = state.loci[enemyHeadID];
        var cavity:BoardLocus = enemyHead.s().s().e();
        cavity.value[occupier_] = 1;

        VisualAssert.assert('two player bite with small cavity in player one', state.spitBoard(plan, true, freshnessBoardMod));

        var totalArea_:AspectPtr = plan.onPlayer(BodyAspect.TOTAL_AREA);
        state.players[0][totalArea_] = ~/([^0])/g.replace(state.spitBoard(plan), '').length;

        biteRule.update();
        var moves:Array<BiteMove> = cast biteRule.moves;
        Assert.areEqual(9 + 6, moves.length);
        var numCells:Int = ~/([^1])/g.replace(state.spitBoard(plan), '').length;
        Assert.areEqual(20, numCells); // 20 cells for player 1

        var cavityID:Int = getID(cavity.value);
        for (move in moves) {
            if (move.bitNodes.has(cavityID)) {
                biteRule.chooseMove(move.id);
                break;
            }
        }

        VisualAssert.assert('two player bite, cavity bitten', state.spitBoard(plan, true, freshnessBoardMod));

        numCells = ~/([^1])/g.replace(state.spitBoard(plan), '').length;
        Assert.areEqual(20 - 1, numCells); // 19 cells for player 1

        testEnemyBody(numCells);
    }

    private function testEnemyBody(expectedSize:Int):Void {
        var bodyFirst_:AspectPtr = plan.onPlayer(BodyAspect.BODY_FIRST);
        var bodyNext_:AspectPtr = plan.onNode(BodyAspect.BODY_NEXT);
        var bodyPrev_:AspectPtr = plan.onNode(BodyAspect.BODY_PREV);
        var bodyNode:AspectSet = state.nodes[state.players[1][bodyFirst_]];

        Assert.areEqual(0, testListLength(expectedSize, bodyNode, bodyNext_, bodyPrev_));
    }
}
