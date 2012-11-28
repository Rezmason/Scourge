package net.rezmason.scourge.model;

import massive.munit.Assert;
import VisualAssert;

import net.rezmason.ropes.Aspect;
import net.rezmason.ropes.ModelTypes;
import net.rezmason.scourge.model.aspects.BodyAspect;
import net.rezmason.scourge.model.aspects.OwnershipAspect;
import net.rezmason.scourge.model.rules.CavityRule;

using net.rezmason.ropes.GridNode;
using net.rezmason.ropes.GridUtils;
using net.rezmason.scourge.model.BoardUtils;
using net.rezmason.ropes.StatePlan;
using net.rezmason.utils.Pointers;

class CavityRuleTest extends RuleTest
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
        trace("tick " + time);
    }
    #end

    @Test
    public function cavityRuleTest():Void {

        var cavityRule:CavityRule = new CavityRule();
        makeState([cavityRule], 1, TestBoards.cavityCity);

        var numCells:Int = ~/([^0])/g.replace(state.spitBoard(plan), "").length;
        var numCavityCells:Int = ~/([^a])/g.replace(state.spitBoard(plan), "").length;

        Assert.areEqual(50, numCells);
        Assert.areEqual(0, numCavityCells);

        VisualAssert.assert("cavity city (empty)", state.spitBoard(plan));

        var totalArea_:AspectPtr = plan.onPlayer(BodyAspect.TOTAL_AREA);
        state.players[0].mod(totalArea_, ~/([^0])/g.replace(state.spitBoard(plan), "").length);

        cavityRule.chooseOption();

        VisualAssert.assert("cavity city (all cavities filled)", state.spitBoard(plan));

        numCells = ~/([^0])/g.replace(state.spitBoard(plan), "").length;
        numCavityCells = ~/([^a])/g.replace(state.spitBoard(plan), "").length;

        Assert.areEqual(50, numCells);
        Assert.areEqual(31, numCavityCells);

        var cavityFirst_:AspectPtr = plan.onPlayer(BodyAspect.CAVITY_FIRST);
        var cavityNext_:AspectPtr = plan.onNode(BodyAspect.CAVITY_NEXT);
        var cavityPrev_:AspectPtr = plan.onNode(BodyAspect.CAVITY_PREV);
        var cavityNode:BoardNode = state.nodes[state.players[0].at(cavityFirst_)];
        Assert.areEqual(0, testListLength(numCavityCells, cavityNode, cavityNext_, cavityPrev_));

        var totalArea_:AspectPtr = plan.onPlayer(BodyAspect.TOTAL_AREA);
        var totalArea:Int = state.players[0].at(totalArea_);
        Assert.areEqual(numCells + numCavityCells, totalArea);
    }

    @Test
    public function cavityRuleTest2():Void {

        var cavityRule:CavityRule = new CavityRule();
        makeState([cavityRule], 1, TestBoards.cavityCity);

        var head_:AspectPtr = plan.onPlayer(BodyAspect.HEAD);
        var head:BoardNode = state.nodes[state.players[0].at(head_)];
        var bump:BoardNode = head.run(Gr.s, 5);

        var occupier_:AspectPtr = plan.onNode(OwnershipAspect.OCCUPIER);
        var isFilled_:AspectPtr = plan.onNode(OwnershipAspect.IS_FILLED);
        bump.value.mod(occupier_, 0);
        bump.value.mod(isFilled_, Aspect.TRUE);

        var totalArea_:AspectPtr = plan.onPlayer(BodyAspect.TOTAL_AREA);
        var totalArea:Int = state.players[0].at(totalArea_);
        state.players[0].mod(totalArea_, totalArea + 1);

        var numCells:Int = ~/([^0])/g.replace(state.spitBoard(plan), "").length;
        var numCavityCells:Int = ~/([^a])/g.replace(state.spitBoard(plan), "").length;

        Assert.areEqual(51, numCells);
        Assert.areEqual(0, numCavityCells);

        VisualAssert.assert("cavity city (empty) with broken moat", state.spitBoard(plan));

        var totalArea_:AspectPtr = plan.onPlayer(BodyAspect.TOTAL_AREA);
        state.players[0].mod(totalArea_, ~/([^0])/g.replace(state.spitBoard(plan), "").length);

        cavityRule.chooseOption();

        VisualAssert.assert("cavity city (all cavities filled) with broken moat", state.spitBoard(plan));

        numCells = ~/([^0])/g.replace(state.spitBoard(plan), "").length;
        numCavityCells = ~/([^a])/g.replace(state.spitBoard(plan), "").length;

        Assert.areEqual(51, numCells);
        Assert.areEqual(31, numCavityCells);

        var cavityFirst_:AspectPtr = plan.onPlayer(BodyAspect.CAVITY_FIRST);
        var cavityNext_:AspectPtr = plan.onNode(BodyAspect.CAVITY_NEXT);
        var cavityPrev_:AspectPtr = plan.onNode(BodyAspect.CAVITY_PREV);
        var cavityNode:BoardNode = state.nodes[state.players[0].at(cavityFirst_)];
        Assert.areEqual(0, testListLength(numCavityCells, cavityNode, cavityNext_, cavityPrev_));

        totalArea = state.players[0].at(totalArea_);
        Assert.areEqual(numCells + numCavityCells, totalArea);
    }
}
