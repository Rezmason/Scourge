package net.rezmason.scourge.model;

import massive.munit.Assert;
import VisualAssert;

import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.aspects.BodyAspect;
import net.rezmason.scourge.model.aspects.FreshnessAspect;
import net.rezmason.scourge.model.aspects.OwnershipAspect;
import net.rezmason.scourge.model.aspects.PlyAspect;
import net.rezmason.scourge.model.aspects.WinAspect;
import net.rezmason.scourge.model.rules.EndTurnRule;
import net.rezmason.scourge.model.rules.ForfeitRule;
import net.rezmason.scourge.model.rules.KillHeadlessPlayerRule;
import net.rezmason.scourge.model.rules.OneLivingPlayerRule;
import net.rezmason.scourge.model.rules.SkipsExhaustedRule;
import net.rezmason.scourge.model.rules.DropPieceRule;
import net.rezmason.scourge.model.rules.TestPieceRule;

// using net.rezmason.scourge.model.GridUtils;
using net.rezmason.scourge.model.BoardUtils;
using net.rezmason.scourge.model.StatePlan;
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
        makeState([endTurnRule], 4, TestBoards.emptySquareFourPlayerSkirmish);

        var currentPlayer_:AspectPtr = plan.onState(PlyAspect.CURRENT_PLAYER);

        var expectedCurrentPlayer:Int = 0;
        var currentPlayer:Int = state.aspects.at(currentPlayer_);

        Assert.areEqual(expectedCurrentPlayer, currentPlayer);

        // Get rid of player 4's head

        var head_:AspectPtr = plan.onPlayer(BodyAspect.HEAD);
        state.players[3].mod(head_, Aspect.NULL);


        endTurnRule.update();
        var options:Array<Option> = endTurnRule.options;
        Assert.isNotNull(options);
        Assert.areEqual(1, options.length);

        while (expectedCurrentPlayer < 10) {
            expectedCurrentPlayer++;
            endTurnRule.chooseOption();
            currentPlayer = state.aspects.at(currentPlayer_);
            Assert.areEqual(expectedCurrentPlayer % 3, currentPlayer);
        }
    }

    @Test
    public function forfeitTest():Void {

        // Should kill and freshen body of current player

        var forfeitRule:ForfeitRule = new ForfeitRule();
        makeState([forfeitRule], 4, TestBoards.oaf);

        var head_:AspectPtr = plan.onPlayer(BodyAspect.HEAD);
        var currentPlayer_:AspectPtr = plan.onState(PlyAspect.CURRENT_PLAYER);
        var occupier_:AspectPtr = plan.onNode(OwnershipAspect.OCCUPIER);
        var isFilled_:AspectPtr = plan.onNode(OwnershipAspect.IS_FILLED);
        var freshness_:AspectPtr = plan.onNode(FreshnessAspect.FRESHNESS);

        var currentPlayer:Int = state.aspects.at(currentPlayer_);
        var head:Int = state.players[currentPlayer].at(head_);
        var playerHead:BoardNode = state.nodes[head];

        forfeitRule.update();
        var options:Array<Option> = forfeitRule.options;
        Assert.isNotNull(options);
        Assert.areEqual(1, options.length);

        VisualAssert.assert("player 0 is alive", state.spitBoard(plan));

        forfeitRule.chooseOption();

        VisualAssert.assert("player 0 is dead and gone", state.spitBoard(plan));

        Assert.areEqual(Aspect.NULL, playerHead.value.at(occupier_));
        Assert.areEqual(0, playerHead.value.at(isFilled_));

        // Player 1 should be gone
        var numCells:Int = ~/([^0])/g.replace(state.spitBoard(plan), "").length;
        Assert.areEqual(0, numCells);

        var bodyFirst_:AspectPtr = plan.onPlayer(BodyAspect.BODY_FIRST);
        Assert.areEqual(Aspect.NULL, state.players[currentPlayer].at(bodyFirst_));
    }

    @Test
    public function killHeadsTest():Void {

        // Should remove heads that are not occupied by their owner

        var killHeadlessPlayerRule:KillHeadlessPlayerRule = new KillHeadlessPlayerRule();
        makeState([killHeadlessPlayerRule], 4);

        // Change occupier of current player's head

        var head_:AspectPtr = plan.onPlayer(BodyAspect.HEAD);
        var currentPlayer_:AspectPtr = plan.onState(PlyAspect.CURRENT_PLAYER);
        var occupier_:AspectPtr = plan.onNode(OwnershipAspect.OCCUPIER);
        var isFilled_:AspectPtr = plan.onNode(OwnershipAspect.IS_FILLED);
        var freshness_:AspectPtr = plan.onNode(FreshnessAspect.FRESHNESS);
        var bodyFirst_:AspectPtr = plan.onPlayer(BodyAspect.BODY_FIRST);

        var currentPlayer:Int = state.aspects.at(currentPlayer_);
        var head:Int = state.players[currentPlayer].at(head_);
        var playerHead:BoardNode = state.nodes[head];

        playerHead.value.mod(occupier_, 1);

        killHeadlessPlayerRule.update();
        var options:Array<Option> = killHeadlessPlayerRule.options;
        Assert.isNotNull(options);
        Assert.areEqual(1, options.length);

        killHeadlessPlayerRule.chooseOption();

        head = state.players[currentPlayer].at(head_);
        Assert.areEqual(Aspect.NULL, head);

        var bodyFirst:Int = state.players[currentPlayer].at(bodyFirst_);
        Assert.areEqual(Aspect.NULL, bodyFirst);
    }

    @Test
    public function skipsExhaustedTest():Void {

        // Create a four-player game with a max skip of five times
        var skipsExhaustedRule:SkipsExhaustedRule = new SkipsExhaustedRule({maxSkips:5});
        makeState([skipsExhaustedRule], 4);

        var winner_:AspectPtr = plan.onState(WinAspect.WINNER);
        var totalArea_:AspectPtr = plan.onPlayer(BodyAspect.TOTAL_AREA);
        var numConsecutiveSkips_:AspectPtr = plan.onPlayer(PlyAspect.NUM_CONSECUTIVE_SKIPS);

        // Have each player skip four times, then check for a winner
        for (ike in 0...state.players.length) {
            var player:AspectSet = state.players[ike];
            player.mod(numConsecutiveSkips_, 4);
            player.mod(totalArea_, 4 - ike);
        }

        skipsExhaustedRule.update();
        skipsExhaustedRule.chooseOption();
        Assert.areEqual(Aspect.NULL, state.aspects.at(winner_));

        // Have each player skip one more time, then check for a winner

        for (ike in 0...state.players.length) {
            var player:AspectSet = state.players[ike];
            player.mod(numConsecutiveSkips_, 5);
            player.mod(totalArea_, 4 - ike);
        }

        skipsExhaustedRule.update();
        skipsExhaustedRule.chooseOption();
        Assert.areEqual(3, state.aspects.at(winner_));
    }

    @Test
    public function onlyLivingPlayerTest():Void {

        // Create a four-player game
        var oneLivingPlayerRule:OneLivingPlayerRule = new OneLivingPlayerRule();
        makeState([oneLivingPlayerRule], 4);

        var winner_:AspectPtr = plan.onState(WinAspect.WINNER);
        var head_:AspectPtr = plan.onPlayer(BodyAspect.HEAD);

        // kill the first, third and fourth players
        for (ike in 0...state.players.length) {
            if (ike == 1) continue; // We're skipping player 2

            var player:AspectSet = state.players[ike];
            player.mod(head_, Aspect.NULL);
        }

        // update and check for a winner

        oneLivingPlayerRule.update();
        oneLivingPlayerRule.chooseOption();
        Assert.areEqual(1, state.aspects.at(winner_));
    }
}
