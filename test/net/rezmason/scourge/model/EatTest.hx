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
    @Before
    public function setup():Void {
        time = massive.munit.util.Timer.stamp();
    }

    @After
    public function tearDown():Void {
        time = massive.munit.util.Timer.stamp() - time;
        trace("tick " + time);
    }

    @Test
    public function eatRuleTest():Void {
        var eatConfig:EatCellsConfig = {recursive:false, eatHeads:true, takeBodiesFromHeads:false};
        var eatRule:EatCellsRule = new EatCellsRule(eatConfig);
        makeState(TestBoards.twoPlayerGrab, 2, cast [eatRule]);

        // set up the board for the test

        var occupier_:AspectPtr = plan.nodeAspectLookup[OwnershipAspect.OCCUPIER.id];
        var isFilled_:AspectPtr = plan.nodeAspectLookup[OwnershipAspect.IS_FILLED.id];
        var freshness_:AspectPtr = plan.nodeAspectLookup[FreshnessAspect.FRESHNESS.id];
        var head_:AspectPtr = plan.playerAspectLookup[BodyAspect.HEAD.id];
        var currentPlayer_:AspectPtr = plan.stateAspectLookup[PlyAspect.CURRENT_PLAYER.id];
        var currentPlayer:Int = state.aspects.at(currentPlayer_);
        var head:Int = state.players[currentPlayer].at(head_);
        var playerHead:BoardNode = state.nodes[head];
        var bodyFirst_:AspectPtr = plan.playerAspectLookup[BodyAspect.BODY_FIRST.id];
        var bodyNext_:AspectPtr = plan.nodeAspectLookup[BodyAspect.BODY_NEXT.id];
        var bodyPrev_:AspectPtr = plan.nodeAspectLookup[BodyAspect.BODY_PREV.id];

        state.freshen(freshness_, 7, 7);
        state.freshen(freshness_, 9, 7);

        var numCells:Int = ~/([^0])/g.replace(state.spitBoard(plan), "").length;
        Assert.areEqual(25, numCells);

        eatRule.update();
        Assert.areEqual(1, eatRule.options.length);

        // straight up eating

        //trace(state.spitBoard(true));
        eatRule.chooseOption(0);
        //trace(state.spitBoard(true));

        numCells = ~/([^0])/g.replace(state.spitBoard(plan), "").length;
        Assert.areEqual(25 + 6, numCells);

        var bodyNode:BoardNode = state.nodes[state.players[0].at(bodyFirst_)];

        Assert.areEqual(0, testListLength(numCells, bodyNode, bodyNext_, bodyPrev_));
    }

    @Test
    public function eatRecursivelyRuleTest():Void {
        var eatConfig:EatCellsConfig = {recursive:true, eatHeads:true, takeBodiesFromHeads:false};
        var eatRule:EatCellsRule = new EatCellsRule(eatConfig);
        makeState(TestBoards.twoPlayerGrab, 2, cast [eatRule]);

        // set up the board for the test

        var occupier_:AspectPtr = plan.nodeAspectLookup[OwnershipAspect.OCCUPIER.id];
        var isFilled_:AspectPtr = plan.nodeAspectLookup[OwnershipAspect.IS_FILLED.id];
        var freshness_:AspectPtr = plan.nodeAspectLookup[FreshnessAspect.FRESHNESS.id];
        var head_:AspectPtr = plan.playerAspectLookup[BodyAspect.HEAD.id];
        var currentPlayer_:AspectPtr = plan.stateAspectLookup[PlyAspect.CURRENT_PLAYER.id];
        var currentPlayer:Int = state.aspects.at(currentPlayer_);
        var head:Int = state.players[currentPlayer].at(head_);
        var playerHead:BoardNode = state.nodes[head];
        var bodyFirst_:AspectPtr = plan.playerAspectLookup[BodyAspect.BODY_FIRST.id];
        var bodyNext_:AspectPtr = plan.nodeAspectLookup[BodyAspect.BODY_NEXT.id];
        var bodyPrev_:AspectPtr = plan.nodeAspectLookup[BodyAspect.BODY_PREV.id];

        state.freshen(freshness_, 7, 7);
        state.freshen(freshness_, 9, 7);

        var numCells:Int = ~/([^0])/g.replace(state.spitBoard(plan), "").length;
        Assert.areEqual(25, numCells);

        // recursive eating

        //trace(state.spitBoard(true));
        eatRule.chooseOption(0);
        //trace(state.spitBoard(true));

        numCells = ~/([^0])/g.replace(state.spitBoard(plan), "").length;
        Assert.areEqual(25 + 6 + 2, numCells);

        var bodyNode:BoardNode = state.nodes[state.players[0].at(bodyFirst_)];

        Assert.areEqual(0, testListLength(numCells, bodyNode, bodyNext_, bodyPrev_));
    }

    @Test
    public function eatHeadAndBodyRuleTest():Void {
        var eatConfig:EatCellsConfig = {recursive:false, eatHeads:true, takeBodiesFromHeads:true};
        var eatRule:EatCellsRule = new EatCellsRule(eatConfig);
        makeState(TestBoards.twoPlayerGrab, 2, cast [eatRule]);

        // set up the board for the test

        var occupier_:AspectPtr = plan.nodeAspectLookup[OwnershipAspect.OCCUPIER.id];
        var isFilled_:AspectPtr = plan.nodeAspectLookup[OwnershipAspect.IS_FILLED.id];
        var freshness_:AspectPtr = plan.nodeAspectLookup[FreshnessAspect.FRESHNESS.id];
        var head_:AspectPtr = plan.playerAspectLookup[BodyAspect.HEAD.id];
        var currentPlayer_:AspectPtr = plan.stateAspectLookup[PlyAspect.CURRENT_PLAYER.id];
        var currentPlayer:Int = state.aspects.at(currentPlayer_);
        var head:Int = state.players[currentPlayer].at(head_);
        var playerHead:BoardNode = state.nodes[head];

        state.freshen(freshness_, 12, 6);

        var numCells:Int = ~/([^0])/g.replace(state.spitBoard(plan), "").length;
        Assert.areEqual(25, numCells);

        eatRule.chooseOption(0);

        //trace(state.spitBoard(true));

        var numCells:Int = ~/([^0])/g.replace(state.spitBoard(plan), "").length;
        Assert.areEqual(25 + 17, numCells); // Eat everything

        var bodyFirst_:AspectPtr = plan.playerAspectLookup[BodyAspect.BODY_FIRST.id];
        var bodyNext_:AspectPtr = plan.nodeAspectLookup[BodyAspect.BODY_NEXT.id];
        var bodyPrev_:AspectPtr = plan.nodeAspectLookup[BodyAspect.BODY_PREV.id];
        var bodyNode:BoardNode = state.nodes[state.players[0].at(bodyFirst_)];

        Assert.areEqual(0, testListLength(numCells, bodyNode, bodyNext_, bodyPrev_));
    }

    @Test
    public function eatHeadKillBodyTest():Void {
        var eatConfig:EatCellsConfig = {recursive:false, eatHeads:true, takeBodiesFromHeads:false};
        var eatRule:EatCellsRule = new EatCellsRule(eatConfig);
        makeState(TestBoards.twoPlayerGrab, 2, cast [eatRule]);

        // set up the board for the test

        var occupier_:AspectPtr = plan.nodeAspectLookup[OwnershipAspect.OCCUPIER.id];
        var isFilled_:AspectPtr = plan.nodeAspectLookup[OwnershipAspect.IS_FILLED.id];
        var freshness_:AspectPtr = plan.nodeAspectLookup[FreshnessAspect.FRESHNESS.id];
        var head_:AspectPtr = plan.playerAspectLookup[BodyAspect.HEAD.id];
        var currentPlayer_:AspectPtr = plan.stateAspectLookup[PlyAspect.CURRENT_PLAYER.id];
        var currentPlayer:Int = state.aspects.at(currentPlayer_);
        var head:Int = state.players[currentPlayer].at(head_);
        var playerHead:BoardNode = state.nodes[head];

        state.freshen(freshness_, 12, 6);

        var numCells:Int = ~/([^0])/g.replace(state.spitBoard(plan), "").length;
        Assert.areEqual(25, numCells);

        eatRule.chooseOption(0);

        //trace(state.spitBoard(true));

        var numCells:Int = ~/([^0])/g.replace(state.spitBoard(plan), "").length;
        Assert.areEqual(25 + 1, numCells); // Only eat the head

        var bodyFirst_:AspectPtr = plan.playerAspectLookup[BodyAspect.BODY_FIRST.id];
        var bodyNext_:AspectPtr = plan.nodeAspectLookup[BodyAspect.BODY_NEXT.id];
        var bodyPrev_:AspectPtr = plan.nodeAspectLookup[BodyAspect.BODY_PREV.id];
        var bodyNode:BoardNode = state.nodes[state.players[0].at(bodyFirst_)];

        Assert.areEqual(0, testListLength(numCells, bodyNode, bodyNext_, bodyPrev_));
    }
}
