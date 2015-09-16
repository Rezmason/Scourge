package net.rezmason.scourge.game.body;

import massive.munit.Assert;
import VisualAssert;

import net.rezmason.praxis.PraxisTypes;
import net.rezmason.praxis.aspect.Aspect;
import net.rezmason.scourge.game.body.BodyAspect;
import net.rezmason.scourge.game.body.DecayActor;
import net.rezmason.scourge.game.body.OwnershipAspect;

using net.rezmason.grid.GridUtils;
using net.rezmason.scourge.game.BoardUtils;
using net.rezmason.praxis.state.StatePlan;
using net.rezmason.utils.pointers.Pointers;

class DecayRuleTest extends ScourgeRuleTest
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
    public function decayScourgeRuleTest():Void {

        var decayRule = TestUtils.makeRule(null, DecayActor, {decayOrthogonallyOnly:true,});
        makeState([decayRule], 1, TestBoards.loosePetri);

        var numCells:Int = ~/([^0])/g.replace(state.spitBoard(plan), '').length;

        Assert.areEqual(17, numCells); // 17 cells for player 0

        VisualAssert.assert('Loose petri', state.spitBoard(plan));

        decayRule.chooseMove();

        VisualAssert.assert('Empty petri, disconnected region gone', state.spitBoard(plan));

        numCells = ~/([^0])/g.replace(state.spitBoard(plan), '').length;
        Assert.areEqual(1, numCells); // only one cell for player 0

        var bodyFirst_ = plan.onPlayer(BodyAspect.BODY_FIRST);
        var bodyNext_ = plan.onSpace(BodyAspect.BODY_NEXT);
        var bodyPrev_ = plan.onSpace(BodyAspect.BODY_PREV);
        var bodySpace = state.spaces[state.players[0][bodyFirst_]];

        Assert.areEqual(0, testListLength(numCells, bodySpace, bodyNext_, bodyPrev_));

        var totalArea_ = plan.onPlayer(BodyAspect.TOTAL_AREA);
        var totalArea:Int = state.players[0][totalArea_];
        Assert.areEqual(numCells, totalArea);
    }

    @Test
    public function decayDiagScourgeRuleTest():Void {

        var decayRule = TestUtils.makeRule(null, DecayActor, {decayOrthogonallyOnly:false,});
        makeState([decayRule], 1, TestBoards.loosePetri);

        var head_ = plan.onPlayer(BodyAspect.HEAD);
        var head:BoardCell = state.cells.getCell(state.players[0][head_]);
        var bump:BoardCell = head.nw();

        var occupier_ = plan.onSpace(OwnershipAspect.OCCUPIER);
        var isFilled_ = plan.onSpace(OwnershipAspect.IS_FILLED);
        bump.value[occupier_] = 0;
        bump.value[isFilled_] = Aspect.TRUE;

        var numCells:Int = ~/([^0])/g.replace(state.spitBoard(plan), '').length;

        Assert.areEqual(18, numCells); // 18 cells for player 0

        VisualAssert.assert('Loose petri', state.spitBoard(plan));

        decayRule.chooseMove();

        VisualAssert.assert('Loose petri', state.spitBoard(plan));

        numCells = ~/([^0])/g.replace(state.spitBoard(plan), '').length;
        Assert.areEqual(18, numCells); // 18 cells for player 0
    }
}
