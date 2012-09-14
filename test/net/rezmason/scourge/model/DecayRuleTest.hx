package net.rezmason.scourge.model;

import massive.munit.Assert;

import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.aspects.BodyAspect;
import net.rezmason.scourge.model.rules.DecayRule;

using net.rezmason.scourge.model.GridUtils;
using net.rezmason.scourge.model.BoardUtils;
using net.rezmason.utils.Pointers;

class DecayRuleTest extends RuleTest
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
    public function decayRuleTest():Void {

        var decayRule:DecayRule = new DecayRule();
        state = makeState(TestBoards.loosePetri, 1, cast [decayRule]);

        var numCells:Int = ~/([^0])/g.replace(state.spitBoard(), "").length;

        Assert.areEqual(17, numCells); // 51 cells for player 0

        //trace(state.spitBoard());
        decayRule.chooseOption(0);
        //trace(state.spitBoard());

        numCells = ~/([^0])/g.replace(state.spitBoard(), "").length;
        Assert.areEqual(1, numCells); // only one cell for player 0

        var bodyFirst_:AspectPtr = state.playerAspectLookup[BodyAspect.BODY_FIRST.id];
        var bodyNext_:AspectPtr = state.nodeAspectLookup[BodyAspect.BODY_NEXT.id];
        var bodyPrev_:AspectPtr = state.nodeAspectLookup[BodyAspect.BODY_PREV.id];
        var bodyNode:BoardNode = state.nodes[history.get(state.players[0].at(bodyFirst_))];

        Assert.areEqual(0, testListLength(numCells, bodyNode, bodyNext_, bodyPrev_));
    }
}
