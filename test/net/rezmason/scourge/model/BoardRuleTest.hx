package net.rezmason.scourge.model;

import massive.munit.Assert;

import net.rezmason.scourge.model.GridNode;
import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.Aspect;
import net.rezmason.scourge.model.aspects.BodyAspect;
import net.rezmason.scourge.model.aspects.OwnershipAspect;
import net.rezmason.scourge.model.aspects.PlyAspect;
import net.rezmason.scourge.model.rules.BuildBoardRule;
import net.rezmason.scourge.model.rules.DraftPlayersRule;

using net.rezmason.scourge.model.GridUtils;
using net.rezmason.scourge.model.BoardUtils;
using net.rezmason.utils.Pointers;

class BoardRuleTest {

    var history:StateHistory;
    var time:Float;

    @BeforeClass
    public function beforeClass():Void {
        history = new StateHistory();
    }

    @AfterClass
    public function afterClass():Void {
        history.wipe();
        history = null;
    }

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
    public function configTest1():Void {

        var boardCfg:BoardConfig = {circular:false, initGrid:null};
        var buildBoardRule:BuildBoardRule = new BuildBoardRule(boardCfg);

        var playerCfg:PlayerConfig = {numPlayers:4};
        var draftPlayersRule:DraftPlayersRule = new DraftPlayersRule(playerCfg);

        var state:State = makeState([draftPlayersRule, buildBoardRule]);

        var occupier_:AspectPtr = state.nodeAspectLookup[OwnershipAspect.OCCUPIER.id];
        var head_:AspectPtr = state.playerAspectLookup[BodyAspect.HEAD.id];

        for (player in state.players) {
            Assert.isNotNull(player.at(head_));
            Assert.areNotEqual(Aspect.NULL, player.at(head_));
        }

        for (node in state.nodes) {
            Assert.isNotNull(node);
            Assert.isNotNull(node.value.at(occupier_));
        }

        #if VISUAL_TEST
            trace("VISUAL ASSERTION: Should appear to be four integers, equally spaced and equally distant from the edges of a box");
            trace(state.spitBoard());
        #else
            Assert.areEqual(TestBoards.emptySquareFourPlayerSkirmish, state.spitBoard(false));
        #end

        var currentPlayer_:AspectPtr = state.stateAspectLookup[PlyAspect.CURRENT_PLAYER.id];
        var currentPlayer:Int = state.aspects.at(currentPlayer_);

        var playerHead:BoardNode = state.nodes[state.players[currentPlayer].at(head_)];

        for (neighbor in playerHead.neighbors) {
            Assert.isNotNull(neighbor);
            Assert.areEqual(Aspect.NULL, neighbor.value.at(occupier_));
            neighbor.value.mod(occupier_, 0);
        }

        Assert.areEqual(0, playerHead.nw().value.at(occupier_));
        Assert.areEqual(0, playerHead.n( ).value.at(occupier_));
        Assert.areEqual(0, playerHead.ne().value.at(occupier_));
        Assert.areEqual(0, playerHead.e( ).value.at(occupier_));
        Assert.areEqual(0, playerHead.se().value.at(occupier_));
        Assert.areEqual(0, playerHead.s( ).value.at(occupier_));
        Assert.areEqual(0, playerHead.sw().value.at(occupier_));
        Assert.areEqual(0, playerHead.w( ).value.at(occupier_));
    }

    @Test
    public function configTest2():Void {

        var boardCfg:BoardConfig = {circular:true, initGrid:null};
        var buildBoardRule:BuildBoardRule = new BuildBoardRule(boardCfg);

        var playerCfg:PlayerConfig = {numPlayers:1};
        var draftPlayersRule:DraftPlayersRule = new DraftPlayersRule(playerCfg);

        var state:State = makeState([draftPlayersRule, buildBoardRule]);

        #if VISUAL_TEST
            trace("VISUAL ASSERTION: Should appear to be an integer in the center of a perfect circle, which should fit neatly in a box");
            trace(state.spitBoard());
        #else
            Assert.areEqual(TestBoards.emptyPetri, state.spitBoard(false));
        #end
    }

    @Test
    public function configTest3():Void {

        var boardCfg:BoardConfig = {circular:false, initGrid:TestBoards.spiral};
        var buildBoardRule:BuildBoardRule = new BuildBoardRule(boardCfg);

        var playerCfg:PlayerConfig = {numPlayers:4};
        var draftPlayersRule:DraftPlayersRule = new DraftPlayersRule(playerCfg);

        var state:State = makeState([draftPlayersRule, buildBoardRule]);

        #if VISUAL_TEST
            trace("VISUAL ASSERTION: Should appear to be a four-player board with a spiral interior");
            trace(state.spitBoard());
        #end

        Assert.areEqual(TestBoards.spiral, state.spitBoard(false));

        var numCells:Int = ~/([^0])/g.replace(state.spitBoard(false), "").length;

        var bodyFirst_:AspectPtr = state.playerAspectLookup[BodyAspect.BODY_FIRST.id];
        var bodyNext_:AspectPtr = state.nodeAspectLookup[BodyAspect.BODY_NEXT.id];
        var bodyPrev_:AspectPtr = state.nodeAspectLookup[BodyAspect.BODY_PREV.id];

        var bodyFirst:Int = state.players[0].at(bodyFirst_);
        Assert.areNotEqual(Aspect.NULL, bodyFirst);

        testListLength(numCells, state, state.nodes[bodyFirst], bodyNext_, bodyPrev_);

        //trace(history.dump());
    }

    private function makeState(rules:Array<Rule>):State {
        history.wipe();
        return new StateFactory().makeState(rules, history);
    }

    private function testListLength(expectedLength:Int, state:State, first:BoardNode, next:AspectPtr, prev:AspectPtr):Void {
        var count:Int = 0;
        var last:BoardNode = null;

        for (node in first.iterate(state, next)) {
            count++;
            last = node;
        }
        Assert.areEqual(expectedLength, count);

        count = 0;
        for (node in last.iterate(state, prev)) {
            count++;
        }
        Assert.areEqual(expectedLength, count);
    }
}
