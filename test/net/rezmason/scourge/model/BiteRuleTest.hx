package net.rezmason.scourge.model;

import massive.munit.Assert;
import VisualAssert;

import net.rezmason.ropes.Aspect;
import net.rezmason.ropes.Types;
import net.rezmason.scourge.model.aspects.BiteAspect;
import net.rezmason.scourge.model.aspects.BodyAspect;
import net.rezmason.scourge.model.aspects.FreshnessAspect;
import net.rezmason.scourge.model.aspects.IdentityAspect;
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
        var biteRule:BiteRule = new BiteRule(biteConfig);
        makeState([biteRule], 2, TestBoards.twoPlayerBite);

        var F_isForFreshness:Hash<String> = new Hash<String>();
        F_isForFreshness.set(FreshnessAspect.FRESHNESS.id, "F");

        VisualAssert.assert("two player bite", state.spitBoard(plan, true, F_isForFreshness));

        var totalArea_:AspectPtr = plan.onPlayer(BodyAspect.TOTAL_AREA);
        state.players[0].mod(totalArea_, ~/([^0])/g.replace(state.spitBoard(plan), "").length);

        biteRule.update();
        var options:Array<BiteOption> = cast biteRule.options;
        Assert.areEqual(9, options.length);
        var numCells:Int = ~/([^1])/g.replace(state.spitBoard(plan), "").length;
        Assert.areEqual(20, numCells); // 20 cells for player 1
        biteRule.chooseOption();

        VisualAssert.assert("two player bite, bite taken up top", state.spitBoard(plan, true, F_isForFreshness));

        numCells = ~/([^1])/g.replace(state.spitBoard(plan), "").length;
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
        var biteRule:BiteRule = new BiteRule(biteConfig);
        makeState([biteRule], 2, TestBoards.twoPlayerBite);

        var F_isForFreshness:Hash<String> = new Hash<String>();
        F_isForFreshness.set(FreshnessAspect.FRESHNESS.id, "F");

        VisualAssert.assert("two player bite", state.spitBoard(plan, true, F_isForFreshness));

        var totalArea_:AspectPtr = plan.onPlayer(BodyAspect.TOTAL_AREA);
        state.players[0].mod(totalArea_, ~/([^0])/g.replace(state.spitBoard(plan), "").length);

        biteRule.update();
        var options:Array<BiteOption> = cast biteRule.options;
        Assert.areEqual(17, options.length);
        var numCells:Int = ~/([^1])/g.replace(state.spitBoard(plan), "").length;
        Assert.areEqual(20, numCells); // 20 cells for player 1

        for (option in options) {
            if (option.bitNodes.length == biteConfig.maxReach) {
                biteRule.chooseOption(option.optionID);
                break;
            }
        }

        VisualAssert.assert("two player bite, three-unit bite down from top", state.spitBoard(plan, true, F_isForFreshness));

        numCells = ~/([^1])/g.replace(state.spitBoard(plan), "").length;
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
        var biteRule:BiteRule = new BiteRule(biteConfig);
        makeState([biteRule], 2, TestBoards.twoPlayerBite);

        var F_isForFreshness:Hash<String> = new Hash<String>();
        F_isForFreshness.set(FreshnessAspect.FRESHNESS.id, "F");

        VisualAssert.assert("two player bite", state.spitBoard(plan, true, F_isForFreshness));

        var totalArea_:AspectPtr = plan.onPlayer(BodyAspect.TOTAL_AREA);
        state.players[0].mod(totalArea_, ~/([^0])/g.replace(state.spitBoard(plan), "").length);

        biteRule.update();
        var options:Array<BiteOption> = cast biteRule.options;
        Assert.areEqual(45, options.length);
        var numCells:Int = ~/([^1])/g.replace(state.spitBoard(plan), "").length;
        Assert.areEqual(20, numCells); // 20 cells for player 1

        stateHistorian.write();

        for (option in options) {
            if (option.bitNodes.length == biteConfig.maxReach) {
                biteRule.chooseOption(option.optionID);
                break;
            }
        }

        VisualAssert.assert("two player bite, three-unit bite down-diagonal from top", state.spitBoard(plan, true, F_isForFreshness));

        numCells = ~/([^1])/g.replace(state.spitBoard(plan), "").length;
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
        var biteRule:BiteRule = new BiteRule(biteConfig);
        makeState([biteRule], 2, TestBoards.twoPlayerBite);

        var F_isForFreshness:Hash<String> = new Hash<String>();
        F_isForFreshness.set(FreshnessAspect.FRESHNESS.id, "F");

        VisualAssert.assert("two player bite", state.spitBoard(plan, true, F_isForFreshness));

        var totalArea_:AspectPtr = plan.onPlayer(BodyAspect.TOTAL_AREA);
        state.players[0].mod(totalArea_, ~/([^0])/g.replace(state.spitBoard(plan), "").length);

        biteRule.update();
        var options:Array<BiteOption> = cast biteRule.options;
        Assert.areEqual(28, options.length);
        var numCells:Int = ~/([^1])/g.replace(state.spitBoard(plan), "").length;
        Assert.areEqual(20, numCells); // 20 cells for player 1

        for (option in options) {
            if (option.bitNodes.length == biteConfig.maxReach) {
                biteRule.chooseOption(option.optionID);
                break;
            }
        }

        VisualAssert.assert("two player bite, two-unit byte along top going east", state.spitBoard(plan, true, F_isForFreshness));

        numCells = ~/([^1])/g.replace(state.spitBoard(plan), "").length;
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
        var biteRule:BiteRule = new BiteRule(biteConfig);
        makeState([biteRule], 2, TestBoards.twoPlayerBite);

        var F_isForFreshness:Hash<String> = new Hash<String>();
        F_isForFreshness.set(FreshnessAspect.FRESHNESS.id, "F");

        var head_:AspectPtr = plan.onPlayer(BodyAspect.HEAD);
        var enemyHeadID:Int = state.players[1].at(head_);

        VisualAssert.assert("two player bite", state.spitBoard(plan, true, F_isForFreshness));

        var totalArea_:AspectPtr = plan.onPlayer(BodyAspect.TOTAL_AREA);
        state.players[0].mod(totalArea_, ~/([^0])/g.replace(state.spitBoard(plan), "").length);

        biteRule.update();
        var options:Array<BiteOption> = cast biteRule.options;
        Assert.areEqual(10, options.length);
        var numCells:Int = ~/([^1])/g.replace(state.spitBoard(plan), "").length;
        Assert.areEqual(20, numCells); // 20 cells for player 1

        for (option in options) {
            if (option.bitNodes.has(enemyHeadID)) {
                biteRule.chooseOption(option.optionID);
                break;
            }
        }
        VisualAssert.assert("two player bite, player one's noggin bit", state.spitBoard(plan, true, F_isForFreshness));


        numCells = ~/([^1])/g.replace(state.spitBoard(plan), "").length;
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

        var biteRule:BiteRule = new BiteRule(biteConfig);
        makeState([biteRule], 2, TestBoards.twoPlayerBite);

        var F_isForFreshness:Hash<String> = new Hash<String>();
        F_isForFreshness.set(FreshnessAspect.FRESHNESS.id, "F");

        VisualAssert.assert("two player bite", state.spitBoard(plan, true, F_isForFreshness));

        var totalArea_:AspectPtr = plan.onPlayer(BodyAspect.TOTAL_AREA);
        state.players[0].mod(totalArea_, ~/([^0])/g.replace(state.spitBoard(plan), "").length);

        biteRule.update();
        var options:Array<BiteOption> = cast biteRule.options;
        Assert.areEqual(20, options.length);
        var numCells:Int = ~/([^1])/g.replace(state.spitBoard(plan), "").length;
        Assert.areEqual(20, numCells); // 20 cells for player 1
        var numBitNodes:Int = 0;
        var thickestOptionID:Int = -1;
        for (option in options) {
            if (numBitNodes < option.bitNodes.length) {
                numBitNodes = option.bitNodes.length;
                thickestOptionID = option.optionID;
            }
        }
        biteRule.chooseOption(thickestOptionID);

        VisualAssert.assert("two player bite, deep bite right through the middle", state.spitBoard(plan, true, F_isForFreshness));

        numCells = ~/([^1])/g.replace(state.spitBoard(plan), "").length;
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
        var biteRule:BiteRule = new BiteRule(biteConfig);
        makeState([biteRule], 2, TestBoards.twoPlayerBite);

        var F_isForFreshness:Hash<String> = new Hash<String>();
        F_isForFreshness.set(FreshnessAspect.FRESHNESS.id, "F");

        var head_:AspectPtr = plan.onPlayer(BodyAspect.HEAD);
        var occupier_:AspectPtr = plan.onNode(OwnershipAspect.OCCUPIER);
        var enemyHeadID:Int = state.players[1].at(head_);
        var enemyHead:BoardNode = state.nodes[enemyHeadID];
        var cavity:BoardNode = enemyHead.s().s().e();
        cavity.value.mod(occupier_, 1);

        VisualAssert.assert("two player bite with small cavity in player one", state.spitBoard(plan, true, F_isForFreshness));

        var totalArea_:AspectPtr = plan.onPlayer(BodyAspect.TOTAL_AREA);
        state.players[0].mod(totalArea_, ~/([^0])/g.replace(state.spitBoard(plan), "").length);

        biteRule.update();
        var options:Array<BiteOption> = cast biteRule.options;
        Assert.areEqual(9 + 6, options.length);
        var numCells:Int = ~/([^1])/g.replace(state.spitBoard(plan), "").length;
        Assert.areEqual(20, numCells); // 20 cells for player 1

        var nodeID_:AspectPtr = plan.onNode(IdentityAspect.NODE_ID);
        var cavityID:Int = cavity.value.at(nodeID_);
        for (option in options) {
            if (option.bitNodes.has(cavityID)) {
                biteRule.chooseOption(option.optionID);
                break;
            }
        }

        VisualAssert.assert("two player bite, cavity bitten", state.spitBoard(plan, true, F_isForFreshness));

        numCells = ~/([^1])/g.replace(state.spitBoard(plan), "").length;
        Assert.areEqual(20 - 1, numCells); // 19 cells for player 1

        testEnemyBody(numCells);
    }

    private function testEnemyBody(expectedSize:Int):Void {
        var bodyFirst_:AspectPtr = plan.onPlayer(BodyAspect.BODY_FIRST);
        var bodyNext_:AspectPtr = plan.onNode(BodyAspect.BODY_NEXT);
        var bodyPrev_:AspectPtr = plan.onNode(BodyAspect.BODY_PREV);
        var bodyNode:BoardNode = state.nodes[state.players[1].at(bodyFirst_)];

        Assert.areEqual(0, testListLength(expectedSize, bodyNode, bodyNext_, bodyPrev_));
    }
}
