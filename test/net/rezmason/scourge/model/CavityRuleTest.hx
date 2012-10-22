package net.rezmason.scourge.model;

import massive.munit.Assert;

import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.aspects.BodyAspect;
import net.rezmason.scourge.model.aspects.OwnershipAspect;
import net.rezmason.scourge.model.rules.CavityRule;

using net.rezmason.scourge.model.GridNode;
using net.rezmason.scourge.model.GridUtils;
using net.rezmason.scourge.model.BoardUtils;
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
        makeState(cast [cavityRule], 1, TestBoards.cavityCity);

        var numCells:Int = ~/([^0])/g.replace(state.spitBoard(plan), "").length;
        var numCavityCells:Int = ~/([^a])/g.replace(state.spitBoard(plan), "").length;

        Assert.areEqual(50, numCells);
        Assert.areEqual(0, numCavityCells);

        //trace(state.spitBoard(plan));
        cavityRule.chooseOption(0);
        //trace(state.spitBoard(plan));

        numCells = ~/([^0])/g.replace(state.spitBoard(plan), "").length;
        numCavityCells = ~/([^a])/g.replace(state.spitBoard(plan), "").length;

        Assert.areEqual(50, numCells);
        Assert.areEqual(31, numCavityCells);

        var cavityFirst_:AspectPtr = plan.playerAspectLookup[BodyAspect.CAVITY_FIRST.id];
        var cavityNext_:AspectPtr = plan.nodeAspectLookup[BodyAspect.CAVITY_NEXT.id];
        var cavityPrev_:AspectPtr = plan.nodeAspectLookup[BodyAspect.CAVITY_PREV.id];
        var cavityNode:BoardNode = state.nodes[state.players[0].at(cavityFirst_)];
        Assert.areEqual(0, testListLength(numCavityCells, cavityNode, cavityNext_, cavityPrev_));

        var totalArea_:AspectPtr = plan.playerAspectLookup[BodyAspect.TOTAL_AREA.id];
        var totalArea:Int = state.players[0].at(totalArea_);
        Assert.areEqual(numCells + numCavityCells, totalArea);
    }

    @Test
    public function cavityRuleTest2():Void {

        var cavityRule:CavityRule = new CavityRule();
        makeState(cast [cavityRule], 1, TestBoards.cavityCity);

        var head_:AspectPtr = plan.playerAspectLookup[BodyAspect.HEAD.id];
        var head:BoardNode = state.nodes[state.players[0].at(head_)];
        var bump:BoardNode = head.run(Gr.s, 5);

        var occupier_:AspectPtr = plan.nodeAspectLookup[OwnershipAspect.OCCUPIER.id];
        var isFilled_:AspectPtr = plan.nodeAspectLookup[OwnershipAspect.IS_FILLED.id];
        bump.value.mod(occupier_, 0);
        bump.value.mod(isFilled_, Aspect.TRUE);

        var totalArea_:AspectPtr = plan.playerAspectLookup[BodyAspect.TOTAL_AREA.id];
        var totalArea:Int = state.players[0].at(totalArea_);
        state.players[0].mod(totalArea_, totalArea + 1);

        var numCells:Int = ~/([^0])/g.replace(state.spitBoard(plan), "").length;
        var numCavityCells:Int = ~/([^a])/g.replace(state.spitBoard(plan), "").length;

        Assert.areEqual(51, numCells);
        Assert.areEqual(0, numCavityCells);

        //trace(state.spitBoard(plan));
        cavityRule.chooseOption(0);
        //trace(state.spitBoard(plan));

        numCells = ~/([^0])/g.replace(state.spitBoard(plan), "").length;
        numCavityCells = ~/([^a])/g.replace(state.spitBoard(plan), "").length;

        Assert.areEqual(51, numCells);
        Assert.areEqual(31, numCavityCells);

        var cavityFirst_:AspectPtr = plan.playerAspectLookup[BodyAspect.CAVITY_FIRST.id];
        var cavityNext_:AspectPtr = plan.nodeAspectLookup[BodyAspect.CAVITY_NEXT.id];
        var cavityPrev_:AspectPtr = plan.nodeAspectLookup[BodyAspect.CAVITY_PREV.id];
        var cavityNode:BoardNode = state.nodes[state.players[0].at(cavityFirst_)];
        Assert.areEqual(0, testListLength(numCavityCells, cavityNode, cavityNext_, cavityPrev_));

        totalArea = state.players[0].at(totalArea_);
        Assert.areEqual(numCells + numCavityCells, totalArea);
    }
}
