package net.rezmason.scourge.model;

import massive.munit.Assert;

import net.rezmason.scourge.model.GridNode;
import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.aspects.BodyAspect;
import net.rezmason.scourge.model.aspects.FreshnessAspect;
import net.rezmason.scourge.model.aspects.OwnershipAspect;
import net.rezmason.scourge.model.aspects.PlyAspect;
import net.rezmason.scourge.model.rules.EatCellsRule;

using net.rezmason.scourge.model.GridUtils;
using net.rezmason.scourge.model.BoardUtils;
using net.rezmason.utils.Pointers;

class EatTest extends RuleTest
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
    public function eatRuleTest():Void {
        var eatConfig:EatCellsConfig = {recursive:false, eatHeads:false, takeBodiesFromHeads:false, orthoOnly:false};
        var eatRule:EatCellsRule = new EatCellsRule(eatConfig);
        makeState(cast [eatRule], 2, TestBoards.twoPlayerGrab);

        // set up the board for the test

        var freshness_:AspectPtr = plan.nodeAspectLookup[FreshnessAspect.FRESHNESS.id];
        var bodyFirst_:AspectPtr = plan.playerAspectLookup[BodyAspect.BODY_FIRST.id];
        var bodyNext_:AspectPtr = plan.nodeAspectLookup[BodyAspect.BODY_NEXT.id];
        var bodyPrev_:AspectPtr = plan.nodeAspectLookup[BodyAspect.BODY_PREV.id];

        state.grabXY(7, 7).value.mod(freshness_, 1);
        state.grabXY(9, 7).value.mod(freshness_, 1);
        state.grabXY(12, 6).value.mod(freshness_, 1);// Don't eat that head!

        var numCells:Int = ~/([^0])/g.replace(state.spitBoard(plan), "").length;
        Assert.areEqual(25, numCells);

        eatRule.update();
        Assert.areEqual(1, eatRule.options.length);

        // straight up eating

        //trace(state.spitBoard(plan, true));
        eatRule.chooseOption(0);
        //trace(state.spitBoard(plan, true));

        numCells = ~/([^0])/g.replace(state.spitBoard(plan), "").length;
        Assert.areEqual(25 + 6, numCells);

        var bodyNode:BoardNode = state.nodes[state.players[0].at(bodyFirst_)];

        Assert.areEqual(0, testListLength(numCells, bodyNode, bodyNext_, bodyPrev_));
    }

    @Test
    public function eatRecursivelyRuleTest():Void {
        var eatConfig:EatCellsConfig = {recursive:true, eatHeads:false, takeBodiesFromHeads:false, orthoOnly:false};
        var eatRule:EatCellsRule = new EatCellsRule(eatConfig);
        makeState(cast [eatRule], 2, TestBoards.twoPlayerGrab);

        // set up the board for the test

        var freshness_:AspectPtr = plan.nodeAspectLookup[FreshnessAspect.FRESHNESS.id];
        var bodyFirst_:AspectPtr = plan.playerAspectLookup[BodyAspect.BODY_FIRST.id];
        var bodyNext_:AspectPtr = plan.nodeAspectLookup[BodyAspect.BODY_NEXT.id];
        var bodyPrev_:AspectPtr = plan.nodeAspectLookup[BodyAspect.BODY_PREV.id];

        state.grabXY(7, 7).value.mod(freshness_, 1);
        state.grabXY(9, 7).value.mod(freshness_, 1);
        state.grabXY(12, 6).value.mod(freshness_, 1);// Don't eat that head!

        var numCells:Int = ~/([^0])/g.replace(state.spitBoard(plan), "").length;
        Assert.areEqual(25, numCells);

        // recursive eating

        //trace(state.spitBoard(plan, true));
        eatRule.chooseOption(0);
        //trace(state.spitBoard(plan, true));

        numCells = ~/([^0])/g.replace(state.spitBoard(plan), "").length;
        Assert.areEqual(25 + 6 + 1, numCells);

        var bodyNode:BoardNode = state.nodes[state.players[0].at(bodyFirst_)];

        Assert.areEqual(0, testListLength(numCells, bodyNode, bodyNext_, bodyPrev_));
    }

    @Test
    public function eatHeadAndBodyRuleTest():Void {
        var eatConfig:EatCellsConfig = {recursive:false, eatHeads:true, takeBodiesFromHeads:true, orthoOnly:false};
        var eatRule:EatCellsRule = new EatCellsRule(eatConfig);
        makeState(cast [eatRule], 2, TestBoards.twoPlayerGrab);

        // set up the board for the test

        var freshness_:AspectPtr = plan.nodeAspectLookup[FreshnessAspect.FRESHNESS.id];
        var bodyFirst_:AspectPtr = plan.playerAspectLookup[BodyAspect.BODY_FIRST.id];
        var bodyNext_:AspectPtr = plan.nodeAspectLookup[BodyAspect.BODY_NEXT.id];
        var bodyPrev_:AspectPtr = plan.nodeAspectLookup[BodyAspect.BODY_PREV.id];

        state.grabXY(12, 6).value.mod(freshness_, 1);

        var numCells:Int = ~/([^0])/g.replace(state.spitBoard(plan), "").length;
        Assert.areEqual(25, numCells);

        eatRule.chooseOption(0);

        //trace(state.spitBoard(plan, true));

        var numCells:Int = ~/([^0])/g.replace(state.spitBoard(plan), "").length;
        Assert.areEqual(25 + 13, numCells); // Eat everything

        var bodyNode:BoardNode = state.nodes[state.players[0].at(bodyFirst_)];

        Assert.areEqual(0, testListLength(numCells, bodyNode, bodyNext_, bodyPrev_));
    }

    @Test
    public function eatHeadKillBodyTest():Void {
        var eatConfig:EatCellsConfig = {recursive:false, eatHeads:true, takeBodiesFromHeads:false, orthoOnly:false};
        var eatRule:EatCellsRule = new EatCellsRule(eatConfig);
        makeState(cast [eatRule], 2, TestBoards.twoPlayerGrab);

        // set up the board for the test

        var freshness_:AspectPtr = plan.nodeAspectLookup[FreshnessAspect.FRESHNESS.id];

        state.grabXY(12, 6).value.mod(freshness_, 1);

        var numCells:Int = ~/([^0])/g.replace(state.spitBoard(plan), "").length;
        Assert.areEqual(25, numCells);

        eatRule.chooseOption(0);

        //trace(state.spitBoard(plan, true));

        var numCells:Int = ~/([^0])/g.replace(state.spitBoard(plan), "").length;
        Assert.areEqual(25 + 1, numCells); // Only eat the head

        var bodyFirst_:AspectPtr = plan.playerAspectLookup[BodyAspect.BODY_FIRST.id];
        var bodyNext_:AspectPtr = plan.nodeAspectLookup[BodyAspect.BODY_NEXT.id];
        var bodyPrev_:AspectPtr = plan.nodeAspectLookup[BodyAspect.BODY_PREV.id];
        var bodyNode:BoardNode = state.nodes[state.players[0].at(bodyFirst_)];

        Assert.areEqual(0, testListLength(numCells, bodyNode, bodyNext_, bodyPrev_));
    }

    @Test
    public function eatOrthoRuleTest():Void {
        var eatConfig:EatCellsConfig = {recursive:true, eatHeads:false, takeBodiesFromHeads:false, orthoOnly:true};
        var eatRule:EatCellsRule = new EatCellsRule(eatConfig);
        makeState(cast [eatRule], 2, TestBoards.twoPlayerN);

        // set up the board for the test

        var freshness_:AspectPtr = plan.nodeAspectLookup[FreshnessAspect.FRESHNESS.id];
        var bodyFirst_:AspectPtr = plan.playerAspectLookup[BodyAspect.BODY_FIRST.id];
        var bodyNext_:AspectPtr = plan.nodeAspectLookup[BodyAspect.BODY_NEXT.id];
        var bodyPrev_:AspectPtr = plan.nodeAspectLookup[BodyAspect.BODY_PREV.id];

        state.grabXY(6, 13).value.mod(freshness_, 1);
        state.grabXY(7, 13).value.mod(freshness_, 1);

        var numCells:Int = ~/([^0])/g.replace(state.spitBoard(plan), "").length;
        Assert.areEqual(76, numCells);

        eatRule.update();
        Assert.areEqual(1, eatRule.options.length);

        // straight up eating

        //trace(state.spitBoard(plan, true));
        eatRule.chooseOption(0);
        //trace(state.spitBoard(plan, true));

        numCells = ~/([^0])/g.replace(state.spitBoard(plan), "").length;
        Assert.areEqual(76 + 14, numCells);

        var bodyNode:BoardNode = state.nodes[state.players[0].at(bodyFirst_)];

        Assert.areEqual(0, testListLength(numCells, bodyNode, bodyNext_, bodyPrev_));
    }


}
