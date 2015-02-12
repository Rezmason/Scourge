package net.rezmason.scourge.model.body;

import massive.munit.Assert;
import VisualAssert;

import net.rezmason.ropes.aspect.Aspect;
import net.rezmason.ropes.RopesTypes;
import net.rezmason.ropes.grid.GridDirection.*;
import net.rezmason.ropes.grid.GridLocus;
import net.rezmason.scourge.model.body.BodyAspect;
import net.rezmason.scourge.model.body.OwnershipAspect;
import net.rezmason.scourge.model.body.CavityRule;


using net.rezmason.ropes.grid.GridUtils;
using net.rezmason.scourge.model.BoardUtils;
using net.rezmason.ropes.state.StatePlan;
using net.rezmason.utils.Pointers;

class CavityRuleTest extends ScourgeRuleTest
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
    public function cavityScourgeRuleTest():Void {

        var cavityRule:CavityRule = new CavityRule();
        cavityRule.init(null);
        makeState([cavityRule], 1, TestBoards.cavityCity);

        var numCells:Int = ~/([^0])/g.replace(state.spitBoard(plan), '').length;
        var numCavityCells:Int = ~/([^a])/g.replace(state.spitBoard(plan), '').length;

        Assert.areEqual(50, numCells);
        Assert.areEqual(0, numCavityCells);

        VisualAssert.assert('cavity city (empty)', state.spitBoard(plan));

        var totalArea_:AspectPtr = plan.onPlayer(BodyAspect.TOTAL_AREA);
        state.players[0][totalArea_] = ~/([^0])/g.replace(state.spitBoard(plan), '').length;

        cavityRule.chooseMove();

        VisualAssert.assert('cavity city (all cavities filled)', state.spitBoard(plan));

        numCells = ~/([^0])/g.replace(state.spitBoard(plan), '').length;
        numCavityCells = ~/([^a])/g.replace(state.spitBoard(plan), '').length;

        Assert.areEqual(50, numCells);
        Assert.areEqual(31, numCavityCells);

        var cavityFirst_:AspectPtr = plan.onPlayer(BodyAspect.CAVITY_FIRST);
        var cavityNext_:AspectPtr = plan.onNode(BodyAspect.CAVITY_NEXT);
        var cavityPrev_:AspectPtr = plan.onNode(BodyAspect.CAVITY_PREV);
        var cavityNode:AspectSet = state.nodes[state.players[0][cavityFirst_]];
        Assert.areEqual(0, testListLength(numCavityCells, cavityNode, cavityNext_, cavityPrev_));

        var totalArea_:AspectPtr = plan.onPlayer(BodyAspect.TOTAL_AREA);
        var totalArea:Int = state.players[0][totalArea_];
        Assert.areEqual(numCells + numCavityCells, totalArea);
    }

    @Test
    public function cavityScourgeRuleTest2():Void {

        var cavityRule:CavityRule = new CavityRule();
        cavityRule.init(null);
        makeState([cavityRule], 1, TestBoards.cavityCity);

        var head_:AspectPtr = plan.onPlayer(BodyAspect.HEAD);
        var head:BoardLocus = state.loci[state.players[0][head_]];
        var bump:BoardLocus = head.run(S, 5);

        var occupier_:AspectPtr = plan.onNode(OwnershipAspect.OCCUPIER);
        var isFilled_:AspectPtr = plan.onNode(OwnershipAspect.IS_FILLED);
        bump.value[occupier_] = 0;
        bump.value[isFilled_] = Aspect.TRUE;

        var totalArea_:AspectPtr = plan.onPlayer(BodyAspect.TOTAL_AREA);
        var totalArea:Int = state.players[0][totalArea_];
        state.players[0][totalArea_] = totalArea + 1;

        var numCells:Int = ~/([^0])/g.replace(state.spitBoard(plan), '').length;
        var numCavityCells:Int = ~/([^a])/g.replace(state.spitBoard(plan), '').length;

        Assert.areEqual(51, numCells);
        Assert.areEqual(0, numCavityCells);

        VisualAssert.assert('cavity city (empty) with broken moat', state.spitBoard(plan));

        var totalArea_:AspectPtr = plan.onPlayer(BodyAspect.TOTAL_AREA);
        state.players[0][totalArea_] = ~/([^0])/g.replace(state.spitBoard(plan), '').length;

        cavityRule.chooseMove();

        VisualAssert.assert('cavity city (all cavities filled) with broken moat', state.spitBoard(plan));

        numCells = ~/([^0])/g.replace(state.spitBoard(plan), '').length;
        numCavityCells = ~/([^a])/g.replace(state.spitBoard(plan), '').length;

        Assert.areEqual(51, numCells);
        Assert.areEqual(31, numCavityCells);

        var cavityFirst_:AspectPtr = plan.onPlayer(BodyAspect.CAVITY_FIRST);
        var cavityNext_:AspectPtr = plan.onNode(BodyAspect.CAVITY_NEXT);
        var cavityPrev_:AspectPtr = plan.onNode(BodyAspect.CAVITY_PREV);
        var cavityNode:AspectSet = state.nodes[state.players[0][cavityFirst_]];
        Assert.areEqual(0, testListLength(numCavityCells, cavityNode, cavityNext_, cavityPrev_));

        totalArea = state.players[0][totalArea_];
        Assert.areEqual(numCells + numCavityCells, totalArea);
    }
}
