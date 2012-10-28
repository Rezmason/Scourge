package net.rezmason.scourge.model;

import massive.munit.Assert;
import VisualAssert;

import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.aspects.BodyAspect;
import net.rezmason.scourge.model.aspects.OwnershipAspect;
import net.rezmason.scourge.model.rules.DecayRule;

using net.rezmason.scourge.model.GridUtils;
using net.rezmason.scourge.model.BoardUtils;
using net.rezmason.utils.Pointers;

class DecayRuleTest extends RuleTest
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
    public function decayRuleTest():Void {

        var cfg:DecayConfig = {
            orthoOnly:true,
        };
        var decayRule:DecayRule = new DecayRule(cfg);
        makeState(cast [decayRule], 1, TestBoards.loosePetri);

        var numCells:Int = ~/([^0])/g.replace(state.spitBoard(plan), "").length;

        Assert.areEqual(17, numCells); // 51 cells for player 0

        VisualAssert.assert("Loose petri", state.spitBoard(plan));

        decayRule.chooseOption(0);

        VisualAssert.assert("Empty petri, disconnected region gone", state.spitBoard(plan));

        numCells = ~/([^0])/g.replace(state.spitBoard(plan), "").length;
        Assert.areEqual(1, numCells); // only one cell for player 0

        var bodyFirst_:AspectPtr = plan.playerAspectLookup[BodyAspect.BODY_FIRST.id];
        var bodyNext_:AspectPtr = plan.nodeAspectLookup[BodyAspect.BODY_NEXT.id];
        var bodyPrev_:AspectPtr = plan.nodeAspectLookup[BodyAspect.BODY_PREV.id];
        var bodyNode:BoardNode = state.nodes[state.players[0].at(bodyFirst_)];

        Assert.areEqual(0, testListLength(numCells, bodyNode, bodyNext_, bodyPrev_));

        var totalArea_:AspectPtr = plan.playerAspectLookup[BodyAspect.TOTAL_AREA.id];
        var totalArea:Int = state.players[0].at(totalArea_);
        Assert.areEqual(numCells, totalArea);
    }

    @Test
    public function decayDiagRuleTest():Void {

        var cfg:DecayConfig = {
            orthoOnly:false,
        };
        var decayRule:DecayRule = new DecayRule(cfg);
        makeState(cast [decayRule], 1, TestBoards.loosePetri);

        var head_:AspectPtr = plan.playerAspectLookup[BodyAspect.HEAD.id];
        var head:BoardNode = state.nodes[state.players[0].at(head_)];
        var bump:BoardNode = head.nw();

        var occupier_:AspectPtr = plan.nodeAspectLookup[OwnershipAspect.OCCUPIER.id];
        var isFilled_:AspectPtr = plan.nodeAspectLookup[OwnershipAspect.IS_FILLED.id];
        bump.value.mod(occupier_, 0);
        bump.value.mod(isFilled_, Aspect.TRUE);

        var numCells:Int = ~/([^0])/g.replace(state.spitBoard(plan), "").length;

        Assert.areEqual(18, numCells); // 51 cells for player 0

        VisualAssert.assert("Loose petri", state.spitBoard(plan));

        decayRule.chooseOption(0);

        VisualAssert.assert("Empty petri, disconnected region gone", state.spitBoard(plan));

        numCells = ~/([^0])/g.replace(state.spitBoard(plan), "").length;
        Assert.areEqual(18, numCells); // only one cell for player 0
    }
}
