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
        state = makeState(TestBoards.oaf, 4, cast [eatRule]);

        // set up the board for the test

        var occupier_:AspectPtr = state.nodeAspectLookup[OwnershipAspect.OCCUPIER.id];
        var isFilled_:AspectPtr = state.nodeAspectLookup[OwnershipAspect.IS_FILLED.id];
        var freshness_:AspectPtr = state.nodeAspectLookup[FreshnessAspect.FRESHNESS.id];
        var head_:AspectPtr = state.playerAspectLookup[BodyAspect.HEAD.id];
        var currentPlayer_:AspectPtr = state.stateAspectLookup[PlyAspect.CURRENT_PLAYER.id];
        var currentPlayer:Int = history.get(state.aspects.at(currentPlayer_));
        var head:Int = history.get(state.players[currentPlayer].at(head_));
        var playerHead:BoardNode = state.nodes[head];

        //var spitAspectProperties:IntHash<String> = new IntHash<String>();
        //spitAspectProperties.set(FreshnessAspect.FRESHNESS.id, "F");

        var cursor:BoardNode = playerHead;
        cursor = cursor.run(Gr.n, 12).run(Gr.e, 6);

        history.set(cursor.value.at(freshness_), 1);

        cursor = cursor.run(Gr.s, 2).run(Gr.e, 2);

        history.set(cursor.value.at(isFilled_), 0);
        history.set(cursor.value.at(occupier_), -1);

        var numCells:Int = ~/([^0])/g.replace(BoardUtils.spitBoard(state), "").length;
        Assert.areEqual(371, numCells);

        eatRule.update();
        Assert.areEqual(1, eatRule.options.length);

        // straight up eating

        //trace(BoardUtils.spitBoard(state, true, spitAspectProperties));
        eatRule.chooseOption(0);
        //trace(BoardUtils.spitBoard(state, true, spitAspectProperties));

        numCells = ~/([^0])/g.replace(BoardUtils.spitBoard(state), "").length;
        Assert.areEqual(389, numCells);
    }

    @Test
    public function eatRecursivelyRuleTest():Void {
        var eatConfig:EatCellsConfig = {recursive:true, eatHeads:true, takeBodiesFromHeads:false};
        var eatRule:EatCellsRule = new EatCellsRule(eatConfig);
        state = makeState(TestBoards.oaf, 4, cast [eatRule]);

        // set up the board for the test

        var occupier_:AspectPtr = state.nodeAspectLookup[OwnershipAspect.OCCUPIER.id];
        var isFilled_:AspectPtr = state.nodeAspectLookup[OwnershipAspect.IS_FILLED.id];
        var freshness_:AspectPtr = state.nodeAspectLookup[FreshnessAspect.FRESHNESS.id];
        var head_:AspectPtr = state.playerAspectLookup[BodyAspect.HEAD.id];
        var currentPlayer_:AspectPtr = state.stateAspectLookup[PlyAspect.CURRENT_PLAYER.id];
        var currentPlayer:Int = history.get(state.aspects.at(currentPlayer_));
        var head:Int = history.get(state.players[currentPlayer].at(head_));
        var playerHead:BoardNode = state.nodes[head];

        //var spitAspectProperties:IntHash<String> = new IntHash<String>();
        //spitAspectProperties.set(FreshnessAspect.FRESHNESS.id, "F");

        var cursor:BoardNode = playerHead;
        cursor = cursor.run(Gr.n, 12).run(Gr.e, 6);

        history.set(cursor.value.at(freshness_), 1);

        cursor = cursor.run(Gr.s, 2).run(Gr.e, 2);

        history.set(cursor.value.at(isFilled_), 0);
        history.set(cursor.value.at(occupier_), -1);

        var numCells:Int = ~/([^0])/g.replace(BoardUtils.spitBoard(state), "").length;
        Assert.areEqual(371, numCells);

        // recursive eating

        //trace(BoardUtils.spitBoard(state, true, spitAspectProperties));
        eatRule.chooseOption(0);
        //trace(BoardUtils.spitBoard(state, true, spitAspectProperties));

        numCells = ~/([^0])/g.replace(BoardUtils.spitBoard(state), "").length;
        Assert.areEqual(483, numCells);
    }

    @Test
    public function eatHeadAndBodyRuleTest():Void {
        var eatConfig:EatCellsConfig = {recursive:true, eatHeads:true, takeBodiesFromHeads:true};
        var eatRule:EatCellsRule = new EatCellsRule(eatConfig);
        state = makeState(TestBoards.spiral, 4, cast [eatRule]);

        // set up the board for the test

        var occupier_:AspectPtr = state.nodeAspectLookup[OwnershipAspect.OCCUPIER.id];
        var isFilled_:AspectPtr = state.nodeAspectLookup[OwnershipAspect.IS_FILLED.id];
        var freshness_:AspectPtr = state.nodeAspectLookup[FreshnessAspect.FRESHNESS.id];
        var head_:AspectPtr = state.playerAspectLookup[BodyAspect.HEAD.id];

        var currentPlayer_:AspectPtr = state.stateAspectLookup[PlyAspect.CURRENT_PLAYER.id];
        var currentPlayer:Int = history.get(state.aspects.at(currentPlayer_));

        // Increment the current player
        currentPlayer++;
        history.set(state.aspects.at(currentPlayer_), currentPlayer);

        var head:Int = history.get(state.players[currentPlayer].at(head_));
        var playerHead:BoardNode = state.nodes[head];

        var cursor:BoardNode = playerHead.w();

        for (ike in 0...12) {
            history.set(cursor.value.at(freshness_), 1);
            history.set(cursor.value.at(occupier_), currentPlayer);
            history.set(cursor.value.at(isFilled_), 1);
            cursor = cursor.s();
        }

        for (ike in 0...3) {
            history.set(cursor.value.at(freshness_), 1);
            history.set(cursor.value.at(occupier_), currentPlayer);
            history.set(cursor.value.at(isFilled_), 1);
            cursor = cursor.e();
        }

        eatRule.update();

        var numCells:Int = ~/([^0])/g.replace(BoardUtils.spitBoard(state), "").length;
        Assert.areEqual(51, numCells);

        // recursive eating

        //trace(BoardUtils.spitBoard(state, true));
        eatRule.chooseOption(0);
        //trace(BoardUtils.spitBoard(state, true));

        numCells = ~/([^0])/g.replace(BoardUtils.spitBoard(state), "").length;
        Assert.areEqual(0, numCells);
    }

    @Test
    public function eatHeadKillBodyTest():Void {
        var eatConfig:EatCellsConfig = {recursive:false, eatHeads:true, takeBodiesFromHeads:false};
        var eatRule:EatCellsRule = new EatCellsRule(eatConfig);
        state = makeState(TestBoards.twoPlayerHeadGrab, 2, cast [eatRule]);

        // set up the board for the test

        var occupier_:AspectPtr = state.nodeAspectLookup[OwnershipAspect.OCCUPIER.id];
        var isFilled_:AspectPtr = state.nodeAspectLookup[OwnershipAspect.IS_FILLED.id];
        var freshness_:AspectPtr = state.nodeAspectLookup[FreshnessAspect.FRESHNESS.id];
        var head_:AspectPtr = state.playerAspectLookup[BodyAspect.HEAD.id];
        var currentPlayer_:AspectPtr = state.stateAspectLookup[PlyAspect.CURRENT_PLAYER.id];
        var currentPlayer:Int = history.get(state.aspects.at(currentPlayer_));
        var head:Int = history.get(state.players[currentPlayer].at(head_));
        var playerHead:BoardNode = state.nodes[head];

        var cursor:BoardNode = playerHead;
        cursor = cursor.run(Gr.n, 7).run(Gr.e, 6);
        history.set(cursor.value.at(freshness_), 1);

        var numCells:Int = ~/([^0])/g.replace(BoardUtils.spitBoard(state), "").length;
        Assert.areEqual(18, numCells);

        eatRule.chooseOption(0);

        //trace(BoardUtils.spitBoard(state, true));

        var numCells:Int = ~/([^0])/g.replace(BoardUtils.spitBoard(state), "").length;
        Assert.areEqual(18 + 1, numCells); // Only eat the head
    }
}
