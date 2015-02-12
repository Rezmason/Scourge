package net.rezmason.scourge.model.build;

import massive.munit.Assert;
import VisualAssert;

import net.rezmason.ropes.aspect.Aspect;
import net.rezmason.ropes.GridLocus;
import net.rezmason.ropes.RopesTypes;
import net.rezmason.scourge.model.body.BodyAspect;
import net.rezmason.scourge.model.body.OwnershipAspect;
import net.rezmason.scourge.model.build.BuildBoardRule;
import net.rezmason.scourge.model.build.BuildPlayersRule;
import net.rezmason.ropes.aspect.PlyAspect;

using net.rezmason.ropes.GridUtils;
using net.rezmason.scourge.model.BoardUtils;
using net.rezmason.ropes.StatePlan;
using net.rezmason.utils.Pointers;

class BoardRuleTest extends ScourgeRuleTest {

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
    public function configTest1():Void {

        makeState(null, 4);

        var occupier_:AspectPtr = plan.onNode(OwnershipAspect.OCCUPIER);
        var head_:AspectPtr = plan.onPlayer(BodyAspect.HEAD);

        for (player in state.players) {
            Assert.isNotNull(player[head_]);
            Assert.areNotEqual(Aspect.NULL, player[head_]);
        }

        for (node in state.nodes) {
            Assert.isNotNull(node);
        }

        VisualAssert.assert('Should appear to be four integers, equally spaced and equally distant from the edges of a box', state.spitBoard(plan));
        Assert.areEqual(TestBoards.emptySquareFourPlayerSkirmish, state.spitBoard(plan, false));

        var currentPlayer_:AspectPtr = plan.onGlobal(PlyAspect.CURRENT_PLAYER);
        var currentPlayer:Int = state.global[currentPlayer_];

        var playerHead:BoardLocus = state.loci[state.players[currentPlayer][head_]];

        for (neighbor in playerHead.neighbors) {
            Assert.isNotNull(neighbor);
            Assert.areEqual(Aspect.NULL, neighbor.value[occupier_]);
            neighbor.value[occupier_] = 0;
        }

        Assert.areEqual(0, playerHead.nw().value[occupier_]);
        Assert.areEqual(0, playerHead.n( ).value[occupier_]);
        Assert.areEqual(0, playerHead.ne().value[occupier_]);
        Assert.areEqual(0, playerHead.e( ).value[occupier_]);
        Assert.areEqual(0, playerHead.se().value[occupier_]);
        Assert.areEqual(0, playerHead.s( ).value[occupier_]);
        Assert.areEqual(0, playerHead.sw().value[occupier_]);
        Assert.areEqual(0, playerHead.w( ).value[occupier_]);
    }

    @Test
    public function configTest2():Void {
        makeState(null, 1, null, true);
        VisualAssert.assert('Should appear to be an integer in the center of a perfect circle, which should fit neatly in a box', state.spitBoard(plan));
        Assert.areEqual(TestBoards.emptyPetri, state.spitBoard(plan, false));
    }

    @Test
    public function configTest3():Void {

        makeState(null, 4, TestBoards.spiral);

        VisualAssert.assert('Should appear to be a four-player board with a spiral interior', state.spitBoard(plan));

        Assert.areEqual(TestBoards.spiral, state.spitBoard(plan, false));

        var numCells:Int = ~/([^0])/g.replace(state.spitBoard(plan, false), '').length;

        var bodyFirst_:AspectPtr = plan.onPlayer(BodyAspect.BODY_FIRST);
        var bodyNext_:AspectPtr = plan.onNode(BodyAspect.BODY_NEXT);
        var bodyPrev_:AspectPtr = plan.onNode(BodyAspect.BODY_PREV);

        var bodyFirst:Int = state.players[0][bodyFirst_];
        Assert.areNotEqual(Aspect.NULL, bodyFirst);

        testListLength(numCells, state.nodes[bodyFirst], bodyNext_, bodyPrev_);
    }
}
