package net.rezmason.scourge.model;

import massive.munit.Assert;
import VisualAssert;

import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.aspects.BodyAspect;
import net.rezmason.scourge.model.aspects.FreshnessAspect;
import net.rezmason.scourge.model.aspects.OwnershipAspect;
import net.rezmason.scourge.model.aspects.PlyAspect;
import net.rezmason.scourge.model.rules.EndTurnRule;
import net.rezmason.scourge.model.rules.ForfeitRule;
import net.rezmason.scourge.model.rules.KillHeadlessPlayerRule;

// using net.rezmason.scourge.model.GridUtils;
using net.rezmason.scourge.model.BoardUtils;
using net.rezmason.utils.Pointers;

class TurnRulesTest extends RuleTest
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
    public function endTurnTest():Void {

        // Should go to the next player who is alive (has a head)

        var endTurnRule:EndTurnRule = new EndTurnRule();
        makeState(cast [endTurnRule], 4, TestBoards.emptySquareFourPlayerSkirmish);

        var currentPlayer_:AspectPtr = plan.stateAspectLookup[PlyAspect.CURRENT_PLAYER.id];

        var expectedCurrentPlayer:Int = 0;
        var currentPlayer:Int = state.aspects.at(currentPlayer_);

        Assert.areEqual(expectedCurrentPlayer, currentPlayer);

        // Get rid of player 4's head

        var head_:AspectPtr = plan.playerAspectLookup[BodyAspect.HEAD.id];
        state.players[3].mod(head_, Aspect.NULL);


        endTurnRule.update();
        var options:Array<Option> = endTurnRule.options;
        Assert.isNotNull(options);
        Assert.areEqual(1, options.length);

        while (expectedCurrentPlayer < 10) {
            expectedCurrentPlayer++;
            endTurnRule.chooseOption(0);
            currentPlayer = state.aspects.at(currentPlayer_);
            Assert.areEqual(expectedCurrentPlayer % 3, currentPlayer);
        }
    }

    @Test
    public function forfeitTest():Void {

        // Should kill and freshen body of current player

        var forfeitRule:ForfeitRule = new ForfeitRule();
        makeState(cast [forfeitRule], 4, TestBoards.oaf);

        var head_:AspectPtr = plan.playerAspectLookup[BodyAspect.HEAD.id];
        var currentPlayer_:AspectPtr = plan.stateAspectLookup[PlyAspect.CURRENT_PLAYER.id];
        var occupier_:AspectPtr = plan.nodeAspectLookup[OwnershipAspect.OCCUPIER.id];
        var isFilled_:AspectPtr = plan.nodeAspectLookup[OwnershipAspect.IS_FILLED.id];
        var freshness_:AspectPtr = plan.nodeAspectLookup[FreshnessAspect.FRESHNESS.id];

        var currentPlayer:Int = state.aspects.at(currentPlayer_);
        var head:Int = state.players[currentPlayer].at(head_);
        var playerHead:BoardNode = state.nodes[head];

        forfeitRule.update();
        var options:Array<Option> = forfeitRule.options;
        Assert.isNotNull(options);
        Assert.areEqual(1, options.length);

        VisualAssert.assert("player 0 is alive", state.spitBoard(plan));

        forfeitRule.chooseOption(0);

        VisualAssert.assert("player 0 is dead and gone", state.spitBoard(plan));

        Assert.areEqual(Aspect.NULL, playerHead.value.at(occupier_));
        Assert.areEqual(0, playerHead.value.at(isFilled_));

        // Player 1 should be gone
        var numCells:Int = ~/([^0])/g.replace(state.spitBoard(plan), "").length;
        Assert.areEqual(0, numCells);

        var bodyFirst_:AspectPtr = plan.playerAspectLookup[BodyAspect.BODY_FIRST.id];
        Assert.areEqual(Aspect.NULL, state.players[currentPlayer].at(bodyFirst_));
    }

    @Test
    public function killHeadsTest():Void {

        // Should remove heads that are not occupied by their owner

        var killHeadlessPlayerRule:KillHeadlessPlayerRule = new KillHeadlessPlayerRule();
        makeState(cast [killHeadlessPlayerRule], 4, TestBoards.emptyPetri);

        // Change occupier of current player's head

        var head_:AspectPtr = plan.playerAspectLookup[BodyAspect.HEAD.id];
        var currentPlayer_:AspectPtr = plan.stateAspectLookup[PlyAspect.CURRENT_PLAYER.id];
        var occupier_:AspectPtr = plan.nodeAspectLookup[OwnershipAspect.OCCUPIER.id];
        var isFilled_:AspectPtr = plan.nodeAspectLookup[OwnershipAspect.IS_FILLED.id];
        var freshness_:AspectPtr = plan.nodeAspectLookup[FreshnessAspect.FRESHNESS.id];
        var bodyFirst_:AspectPtr = plan.playerAspectLookup[BodyAspect.BODY_FIRST.id];

        var currentPlayer:Int = state.aspects.at(currentPlayer_);
        var head:Int = state.players[currentPlayer].at(head_);
        var playerHead:BoardNode = state.nodes[head];

        playerHead.value.mod(occupier_, 1);

        killHeadlessPlayerRule.update();
        var options:Array<Option> = killHeadlessPlayerRule.options;
        Assert.isNotNull(options);
        Assert.areEqual(1, options.length);

        killHeadlessPlayerRule.chooseOption(0);

        head = state.players[currentPlayer].at(head_);
        Assert.areEqual(Aspect.NULL, head);

        var bodyFirst:Int = state.players[currentPlayer].at(bodyFirst_);
        Assert.areEqual(Aspect.NULL, bodyFirst);
    }
}
