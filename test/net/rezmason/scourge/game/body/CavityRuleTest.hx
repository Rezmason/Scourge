package net.rezmason.scourge.game.body;

import massive.munit.Assert;
import VisualAssert;

import net.rezmason.praxis.aspect.Aspect;
import net.rezmason.praxis.PraxisTypes;
import net.rezmason.grid.GridDirection.*;
import net.rezmason.grid.Cell;
import net.rezmason.scourge.game.body.BodyAspect;
import net.rezmason.scourge.game.body.OwnershipAspect;
import net.rezmason.scourge.game.body.CavityRule;


using net.rezmason.grid.GridUtils;
using net.rezmason.scourge.game.BoardUtils;
using net.rezmason.praxis.state.StatePlan;
using net.rezmason.utils.pointers.Pointers;

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

        var cavityRule:CavityRule = TestUtils.makeRule(CavityRule, null);
        makeState([cavityRule], 1, TestBoards.cavityCity);

        var numCells:Int = ~/([^0])/g.replace(state.spitBoard(plan), '').length;
        var numCavityCells:Int = ~/([^a])/g.replace(state.spitBoard(plan), '').length;

        Assert.areEqual(50, numCells);
        Assert.areEqual(0, numCavityCells);

        VisualAssert.assert('cavity city (empty)', state.spitBoard(plan));

        var totalArea_ = plan.onPlayer(BodyAspect.TOTAL_AREA);
        state.players[0][totalArea_] = ~/([^0])/g.replace(state.spitBoard(plan), '').length;

        cavityRule.chooseMove();

        VisualAssert.assert('cavity city (all cavities filled)', state.spitBoard(plan));

        numCells = ~/([^0])/g.replace(state.spitBoard(plan), '').length;
        numCavityCells = ~/([^a])/g.replace(state.spitBoard(plan), '').length;

        Assert.areEqual(50, numCells);
        Assert.areEqual(31, numCavityCells);

        var cavityFirst_ = plan.onPlayer(BodyAspect.CAVITY_FIRST);
        var cavityNext_ = plan.onSpace(BodyAspect.CAVITY_NEXT);
        var cavityPrev_ = plan.onSpace(BodyAspect.CAVITY_PREV);
        var cavitySpace = state.spaces[state.players[0][cavityFirst_]];
        Assert.areEqual(0, testListLength(numCavityCells, cavitySpace, cavityNext_, cavityPrev_));

        var totalArea_ = plan.onPlayer(BodyAspect.TOTAL_AREA);
        var totalArea:Int = state.players[0][totalArea_];
        Assert.areEqual(numCells + numCavityCells, totalArea);
    }

    @Test
    public function cavityScourgeRuleTest2():Void {

        var cavityRule:CavityRule = TestUtils.makeRule(CavityRule, null);
        makeState([cavityRule], 1, TestBoards.cavityCity);

        var head_ = plan.onPlayer(BodyAspect.HEAD);
        var head:BoardCell = state.cells.getCell(state.players[0][head_]);
        var bump:BoardCell = head.run(S, 5);

        var occupier_ = plan.onSpace(OwnershipAspect.OCCUPIER);
        var isFilled_ = plan.onSpace(OwnershipAspect.IS_FILLED);
        bump.value[occupier_] = 0;
        bump.value[isFilled_] = Aspect.TRUE;

        var totalArea_ = plan.onPlayer(BodyAspect.TOTAL_AREA);
        var totalArea:Int = state.players[0][totalArea_];
        state.players[0][totalArea_] = totalArea + 1;

        var numCells:Int = ~/([^0])/g.replace(state.spitBoard(plan), '').length;
        var numCavityCells:Int = ~/([^a])/g.replace(state.spitBoard(plan), '').length;

        Assert.areEqual(51, numCells);
        Assert.areEqual(0, numCavityCells);

        VisualAssert.assert('cavity city (empty) with broken moat', state.spitBoard(plan));

        var totalArea_ = plan.onPlayer(BodyAspect.TOTAL_AREA);
        state.players[0][totalArea_] = ~/([^0])/g.replace(state.spitBoard(plan), '').length;

        cavityRule.chooseMove();

        VisualAssert.assert('cavity city (all cavities filled) with broken moat', state.spitBoard(plan));

        numCells = ~/([^0])/g.replace(state.spitBoard(plan), '').length;
        numCavityCells = ~/([^a])/g.replace(state.spitBoard(plan), '').length;

        Assert.areEqual(51, numCells);
        Assert.areEqual(31, numCavityCells);

        var cavityFirst_ = plan.onPlayer(BodyAspect.CAVITY_FIRST);
        var cavityNext_ = plan.onSpace(BodyAspect.CAVITY_NEXT);
        var cavityPrev_ = plan.onSpace(BodyAspect.CAVITY_PREV);
        var cavitySpace = state.spaces[state.players[0][cavityFirst_]];
        Assert.areEqual(0, testListLength(numCavityCells, cavitySpace, cavityNext_, cavityPrev_));

        totalArea = state.players[0][totalArea_];
        Assert.areEqual(numCells + numCavityCells, totalArea);
    }
}
