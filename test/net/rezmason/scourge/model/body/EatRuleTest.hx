package net.rezmason.scourge.model.body;

import massive.munit.Assert;
import VisualAssert;

import net.rezmason.praxis.grid.GridLocus;
import net.rezmason.praxis.PraxisTypes;
import net.rezmason.scourge.model.body.BodyAspect;
import net.rezmason.scourge.model.body.OwnershipAspect;
import net.rezmason.scourge.model.body.EatCellsRule;
import net.rezmason.scourge.model.meta.FreshnessAspect;
import net.rezmason.praxis.aspect.PlyAspect;

using net.rezmason.praxis.grid.GridUtils;
using net.rezmason.scourge.model.BoardUtils;
using net.rezmason.praxis.state.StatePlan;
using net.rezmason.utils.Pointers;

class EatRuleTest extends ScourgeRuleTest
{
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
    public function eatScourgeRuleTest():Void {
        var eatParams:EatCellsParams = {
            eatRecursively:false, 
            eatHeads:false, 
            takeBodiesFromEatenHeads:false, 
            eatOrthogonallyOnly:false
        };
        var eatRule:EatCellsRule = new EatCellsRule();
        eatRule.init(eatParams);
        makeState([eatRule], 2, TestBoards.twoPlayerGrab);

        // set up the board for the test

        var freshness_:AspectPtr = plan.onNode(FreshnessAspect.FRESHNESS);
        var bodyFirst_:AspectPtr = plan.onPlayer(BodyAspect.BODY_FIRST);
        var bodyNext_:AspectPtr = plan.onNode(BodyAspect.BODY_NEXT);
        var bodyPrev_:AspectPtr = plan.onNode(BodyAspect.BODY_PREV);

        state.grabXY(7, 7).value[freshness_] = 1;
        state.grabXY(9, 7).value[freshness_] = 1;
        state.grabXY(12, 6).value[freshness_] = 1; // Don't eat that head!

        var numCells:Int = ~/([^0])/g.replace(state.spitBoard(plan), '').length;
        Assert.areEqual(25, numCells);

        eatRule.update();
        Assert.areEqual(1, eatRule.moves.length);

        // straight up eating

        VisualAssert.assert('two player grab', state.spitBoard(plan));

        eatRule.chooseMove();

        VisualAssert.assert('two player grab, vertical portions of horseshoe arm eaten', state.spitBoard(plan));

        numCells = ~/([^0])/g.replace(state.spitBoard(plan), '').length;
        Assert.areEqual(25 + 6, numCells);

        var bodyNode:AspectSet = state.nodes[state.players[0][bodyFirst_]];

        Assert.areEqual(0, testListLength(numCells, bodyNode, bodyNext_, bodyPrev_));
    }

    @Test
    public function eatRecursivelyScourgeRuleTest():Void {
        var eatParams:EatCellsParams = {
            eatRecursively:true, 
            eatHeads:false, 
            takeBodiesFromEatenHeads:false, 
            eatOrthogonallyOnly:false
        };
        var eatRule:EatCellsRule = new EatCellsRule();
        eatRule.init(eatParams);
        makeState([eatRule], 2, TestBoards.twoPlayerGrab);

        // set up the board for the test

        var freshness_:AspectPtr = plan.onNode(FreshnessAspect.FRESHNESS);
        var bodyFirst_:AspectPtr = plan.onPlayer(BodyAspect.BODY_FIRST);
        var bodyNext_:AspectPtr = plan.onNode(BodyAspect.BODY_NEXT);
        var bodyPrev_:AspectPtr = plan.onNode(BodyAspect.BODY_PREV);

        state.grabXY(7, 7).value[freshness_] = 1;
        state.grabXY(9, 7).value[freshness_] = 1;
        state.grabXY(12, 6).value[freshness_] = 1; // Don't eat that head!

        var numCells:Int = ~/([^0])/g.replace(state.spitBoard(plan), '').length;
        Assert.areEqual(25, numCells);

        // recursive eating

        VisualAssert.assert('two player grab', state.spitBoard(plan));

        eatRule.chooseMove();

        VisualAssert.assert('two player grab, horseshoe arms eaten', state.spitBoard(plan));

        numCells = ~/([^0])/g.replace(state.spitBoard(plan), '').length;
        Assert.areEqual(25 + 6 + 1, numCells);

        var bodyNode:AspectSet = state.nodes[state.players[0][bodyFirst_]];

        Assert.areEqual(0, testListLength(numCells, bodyNode, bodyNext_, bodyPrev_));
    }

    @Test
    public function eatHeadAndBodyScourgeRuleTest():Void {
        var eatParams:EatCellsParams = {
            eatRecursively:false, 
            eatHeads:true, 
            takeBodiesFromEatenHeads:true, 
            eatOrthogonallyOnly:false
        };
        var eatRule:EatCellsRule = new EatCellsRule();
        eatRule.init(eatParams);
        makeState([eatRule], 2, TestBoards.twoPlayerGrab);

        // set up the board for the test

        var freshness_:AspectPtr = plan.onNode(FreshnessAspect.FRESHNESS);
        var bodyFirst_:AspectPtr = plan.onPlayer(BodyAspect.BODY_FIRST);
        var bodyNext_:AspectPtr = plan.onNode(BodyAspect.BODY_NEXT);
        var bodyPrev_:AspectPtr = plan.onNode(BodyAspect.BODY_PREV);

        state.grabXY(12, 6).value[freshness_] = 1;

        var numCells:Int = ~/([^0])/g.replace(state.spitBoard(plan), '').length;
        Assert.areEqual(25, numCells);

        VisualAssert.assert('two player grab', state.spitBoard(plan));

        eatRule.chooseMove();

        VisualAssert.assert('two player grab, player one eaten', state.spitBoard(plan));

        var numCells:Int = ~/([^0])/g.replace(state.spitBoard(plan), '').length;
        Assert.areEqual(25 + 13, numCells); // Eat everything

        var bodyNode:AspectSet = state.nodes[state.players[0][bodyFirst_]];

        Assert.areEqual(0, testListLength(numCells, bodyNode, bodyNext_, bodyPrev_));
    }

    @Test
    public function eatHeadKillBodyTest():Void {
        var eatParams:EatCellsParams = {
            eatRecursively:false, 
            eatHeads:true, 
            takeBodiesFromEatenHeads:false, 
            eatOrthogonallyOnly:false
        };
        var eatRule:EatCellsRule = new EatCellsRule();
        eatRule.init(eatParams);
        makeState([eatRule], 2, TestBoards.twoPlayerGrab);

        // set up the board for the test

        var freshness_:AspectPtr = plan.onNode(FreshnessAspect.FRESHNESS);

        state.grabXY(12, 6).value[freshness_] = 1;

        var numCells:Int = ~/([^0])/g.replace(state.spitBoard(plan), '').length;
        Assert.areEqual(25, numCells);

        eatRule.chooseMove();

        VisualAssert.assert('two player grab, player one head eaten', state.spitBoard(plan));

        var numCells:Int = ~/([^0])/g.replace(state.spitBoard(plan), '').length;
        Assert.areEqual(25 + 1, numCells); // Only eat the head

        var bodyFirst_:AspectPtr = plan.onPlayer(BodyAspect.BODY_FIRST);
        var bodyNext_:AspectPtr = plan.onNode(BodyAspect.BODY_NEXT);
        var bodyPrev_:AspectPtr = plan.onNode(BodyAspect.BODY_PREV);
        var bodyNode:AspectSet = state.nodes[state.players[0][bodyFirst_]];

        Assert.areEqual(0, testListLength(numCells, bodyNode, bodyNext_, bodyPrev_));
    }

    @Test
    public function eatOrthoScourgeRuleTest():Void {
        var eatParams:EatCellsParams = {
            eatRecursively:true, 
            eatHeads:false, 
            takeBodiesFromEatenHeads:false, 
            eatOrthogonallyOnly:true
        };
        var eatRule:EatCellsRule = new EatCellsRule();
        eatRule.init(eatParams);
        makeState([eatRule], 2, TestBoards.twoPlayerN);

        // set up the board for the test

        var freshness_:AspectPtr = plan.onNode(FreshnessAspect.FRESHNESS);
        var bodyFirst_:AspectPtr = plan.onPlayer(BodyAspect.BODY_FIRST);
        var bodyNext_:AspectPtr = plan.onNode(BodyAspect.BODY_NEXT);
        var bodyPrev_:AspectPtr = plan.onNode(BodyAspect.BODY_PREV);

        state.grabXY(6, 13).value[freshness_] = 1;
        state.grabXY(7, 13).value[freshness_] = 1;

        var numCells:Int = ~/([^0])/g.replace(state.spitBoard(plan), '').length;
        Assert.areEqual(76, numCells);

        eatRule.update();
        Assert.areEqual(1, eatRule.moves.length);

        // straight up eating

        VisualAssert.assert('two player N', state.spitBoard(plan));

        eatRule.chooseMove();

        VisualAssert.assert('two player N, left descender eaten', state.spitBoard(plan));

        numCells = ~/([^0])/g.replace(state.spitBoard(plan), '').length;
        Assert.areEqual(76 + 14, numCells);

        var bodyNode:AspectSet = state.nodes[state.players[0][bodyFirst_]];

        Assert.areEqual(0, testListLength(numCells, bodyNode, bodyNext_, bodyPrev_));
    }


}
