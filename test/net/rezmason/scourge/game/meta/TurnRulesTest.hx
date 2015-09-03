package net.rezmason.scourge.game.meta;

import massive.munit.Assert;
import VisualAssert;

import net.rezmason.praxis.aspect.Aspect;
import net.rezmason.praxis.PraxisTypes;
import net.rezmason.scourge.game.body.BodyAspect;
import net.rezmason.scourge.game.body.OwnershipAspect;
import net.rezmason.scourge.game.piece.DropPieceRule;
import net.rezmason.praxis.aspect.PlyAspect;
import net.rezmason.scourge.game.meta.SkipAspect;
import net.rezmason.praxis.aspect.WinAspect;
import net.rezmason.scourge.game.meta.EndTurnRule;
import net.rezmason.scourge.game.meta.ForfeitRule;
import net.rezmason.scourge.game.meta.KillHeadlessBodyRule;
import net.rezmason.scourge.game.meta.OneLivingPlayerRule;
import net.rezmason.scourge.game.meta.StalemateRule;
import net.rezmason.scourge.game.test.TestPieceRule;

// using net.rezmason.grid.GridUtils;
using net.rezmason.scourge.game.BoardUtils;
using net.rezmason.praxis.state.StatePlan;
using net.rezmason.utils.pointers.Pointers;

class TurnRulesTest extends ScourgeRuleTest
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
    public function endTurnTest():Void {

        // Should go to the next player who is alive (has a head)

        var endTurnRule:EndTurnRule = new EndTurnRule(null);
        makeState([endTurnRule], 4, TestBoards.emptySquareFourPlayerSkirmish);

        var currentPlayer_:AspectPtr = plan.onGlobal(PlyAspect.CURRENT_PLAYER);

        var expectedCurrentPlayer:Int = 0;
        var currentPlayer:Int = state.global[currentPlayer_];

        Assert.areEqual(expectedCurrentPlayer, currentPlayer);

        // Get rid of player 4's head

        var head_:AspectPtr = plan.onPlayer(BodyAspect.HEAD);
        state.players[3][head_] = Aspect.NULL;


        endTurnRule.update();
        var moves:Array<Move> = endTurnRule.moves;
        Assert.isNotNull(moves);
        Assert.areEqual(1, moves.length);

        while (expectedCurrentPlayer < 10) {
            expectedCurrentPlayer++;
            endTurnRule.chooseMove();
            currentPlayer = state.global[currentPlayer_];
            Assert.areEqual(expectedCurrentPlayer % 3, currentPlayer);
        }
    }

    @Test
    public function forfeitTest():Void {

        // Should unassign head of current player

        var forfeitRule:ForfeitRule = new ForfeitRule(null);
        makeState([forfeitRule], 4, TestBoards.oaf);

        var head_:AspectPtr = plan.onPlayer(BodyAspect.HEAD);
        var currentPlayer_:AspectPtr = plan.onGlobal(PlyAspect.CURRENT_PLAYER);
        var occupier_:AspectPtr = plan.onSpace(OwnershipAspect.OCCUPIER);
        var isFilled_:AspectPtr = plan.onSpace(OwnershipAspect.IS_FILLED);

        var currentPlayer:Int = state.global[currentPlayer_];
        var head:Int = state.players[currentPlayer][head_];
        var playerHead:AspectSet = state.spaces[head];

        forfeitRule.update();
        var moves:Array<Move> = forfeitRule.moves;
        Assert.isNotNull(moves);
        Assert.areEqual(1, moves.length);

        VisualAssert.assert('player 0 is alive', state.spitBoard(plan));

        forfeitRule.chooseMove();

        VisualAssert.assert('player 0 is still on the board', state.spitBoard(plan));

        Assert.areEqual(Aspect.NULL, state.players[currentPlayer][head_]);
        Assert.areEqual(currentPlayer, playerHead[occupier_]);
        Assert.areEqual(Aspect.TRUE, playerHead[isFilled_]);

        // Player 0 should still be there, though
        var numCells:Int = ~/([^0])/g.replace(state.spitBoard(plan), '').length;
        Assert.areEqual(371, numCells);
    }

    @Test
    public function killHeadsTest():Void {

        // Should remove heads that are not occupied by their owner

        var killHeadlessBodyRule:KillHeadlessBodyRule = new KillHeadlessBodyRule(null);
        makeState([killHeadlessBodyRule], 4);

        // Change occupier of current player\'s head

        var head_:AspectPtr = plan.onPlayer(BodyAspect.HEAD);
        var currentPlayer_:AspectPtr = plan.onGlobal(PlyAspect.CURRENT_PLAYER);
        var occupier_:AspectPtr = plan.onSpace(OwnershipAspect.OCCUPIER);
        var isFilled_:AspectPtr = plan.onSpace(OwnershipAspect.IS_FILLED);
        var bodyFirst_:AspectPtr = plan.onPlayer(BodyAspect.BODY_FIRST);

        var currentPlayer:Int = state.global[currentPlayer_];
        var head:Int = state.players[currentPlayer][head_];
        var playerHead:AspectSet = state.spaces[head];

        playerHead[occupier_] = 1;

        killHeadlessBodyRule.update();
        var moves:Array<Move> = killHeadlessBodyRule.moves;
        Assert.isNotNull(moves);
        Assert.areEqual(1, moves.length);

        killHeadlessBodyRule.chooseMove();

        head = state.players[currentPlayer][head_];
        Assert.areEqual(Aspect.NULL, head);

        var bodyFirst:Int = state.players[currentPlayer][bodyFirst_];
        Assert.areEqual(Aspect.NULL, bodyFirst);
    }

    @Test
    public function skipsExhaustedTest():Void {

        // Create a four-player game with a max skip of five times
        var stalemateRule:StalemateRule = new StalemateRule({maxSkips:5});
        makeState([stalemateRule], 4);

        var winner_:AspectPtr = plan.onGlobal(WinAspect.WINNER);
        var totalArea_:AspectPtr = plan.onPlayer(BodyAspect.TOTAL_AREA);
        var numConsecutiveSkips_:AspectPtr = plan.onPlayer(SkipAspect.NUM_CONSECUTIVE_SKIPS);

        // Have each player skip four times, then check for a winner
        for (ike in 0...state.players.length) {
            var player:AspectSet = state.players[ike];
            player[numConsecutiveSkips_] = 4;
            player[totalArea_] = 4 - ike;
        }

        stalemateRule.update();
        stalemateRule.chooseMove();
        Assert.areEqual(Aspect.NULL, state.global[winner_]);

        // Have each player skip one more time, then check for a winner

        for (ike in 0...state.players.length) {
            var player:AspectSet = state.players[ike];
            player[numConsecutiveSkips_] = 5;
            player[totalArea_] = 4 - ike;
        }

        stalemateRule.update();
        stalemateRule.chooseMove();
        Assert.areEqual(3, state.global[winner_]);
    }

    @Test
    public function onlyLivingPlayerTest():Void {

        // Create a four-player game
        var oneLivingPlayerRule:OneLivingPlayerRule = new OneLivingPlayerRule(null);
        makeState([oneLivingPlayerRule], 4);

        var winner_:AspectPtr = plan.onGlobal(WinAspect.WINNER);
        var head_:AspectPtr = plan.onPlayer(BodyAspect.HEAD);

        // kill the first, third and fourth players
        for (ike in 0...state.players.length) {
            if (ike == 1) continue; // We\'re skipping player 2

            var player:AspectSet = state.players[ike];
            player[head_] = Aspect.NULL;
        }

        // update and check for a winner

        oneLivingPlayerRule.update();
        oneLivingPlayerRule.chooseMove();
        Assert.areEqual(1, state.global[winner_]);
    }
}
