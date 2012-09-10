package net.rezmason.scourge.model;

import massive.munit.Assert;

import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.aspects.BodyAspect;
import net.rezmason.scourge.model.aspects.FreshnessAspect;
import net.rezmason.scourge.model.aspects.OwnershipAspect;
import net.rezmason.scourge.model.aspects.PlyAspect;
import net.rezmason.scourge.model.rules.EndTurnRule;
import net.rezmason.scourge.model.rules.ForfeitRule;
import net.rezmason.scourge.model.rules.KillHeadsRule;

// using net.rezmason.scourge.model.GridUtils;
using net.rezmason.utils.Pointers;

class TurnRulesTest extends RuleTest
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
    public function endTurnTest():Void {

        // Should go to the next player who is alive (has a head)

        var endTurnRule:EndTurnRule = new EndTurnRule();
        state = makeState(TestBoards.emptySquareFourPlayerSkirmish, 4, cast [endTurnRule]);

        var currentPlayer_:AspectPtr = state.stateAspectLookup[PlyAspect.CURRENT_PLAYER.id];

        var expectedCurrentPlayer:Int = 0;
        var currentPlayer:Int = history.get(state.aspects.at(currentPlayer_));

        Assert.areEqual(expectedCurrentPlayer, currentPlayer);

        // Get rid of player 4's head

        var head_:AspectPtr = state.playerAspectLookup[BodyAspect.HEAD.id];
        history.set(state.players[3].at(head_), -1);


        endTurnRule.update();
        var options:Array<Option> = endTurnRule.options;
        Assert.isNotNull(options);
        Assert.areEqual(1, options.length);

        while (expectedCurrentPlayer < 10) {
            expectedCurrentPlayer++;
            endTurnRule.chooseOption(0);
            currentPlayer = history.get(state.aspects.at(currentPlayer_));
            Assert.areEqual(expectedCurrentPlayer % 3, currentPlayer);
        }
    }

    @Test
    public function forfeitTest():Void {

        // Should kill and freshen body of current player

        var forfeitRule:ForfeitRule = new ForfeitRule();
        state = makeState(TestBoards.oaf, 4, cast [forfeitRule]);

        var head_:AspectPtr = state.playerAspectLookup[BodyAspect.HEAD.id];
        var currentPlayer_:AspectPtr = state.stateAspectLookup[PlyAspect.CURRENT_PLAYER.id];
        var occupier_:AspectPtr = state.nodeAspectLookup[OwnershipAspect.OCCUPIER.id];
        var isFilled_:AspectPtr = state.nodeAspectLookup[OwnershipAspect.IS_FILLED.id];
        var freshness_:AspectPtr = state.nodeAspectLookup[FreshnessAspect.FRESHNESS.id];

        var currentPlayer:Int = history.get(state.aspects.at(currentPlayer_));
        var head:Int = history.get(state.players[currentPlayer].at(head_));
        var playerHead:BoardNode = state.nodes[head];

        forfeitRule.update();
        var options:Array<Option> = forfeitRule.options;
        Assert.isNotNull(options);
        Assert.areEqual(1, options.length);

        //trace(BoardUtils.spitBoard(state));
        forfeitRule.chooseOption(0);
        //trace(BoardUtils.spitBoard(state));

        Assert.areEqual(-1, history.get(playerHead.value.at(occupier_)));
        Assert.areEqual(0, history.get(playerHead.value.at(isFilled_)));

        // Player 1 should be gone
        var numCells:Int = ~/([^0])/g.replace(BoardUtils.spitBoard(state), "").length;
        Assert.areEqual(0, numCells);
    }

    @Test
    public function killHeadsTest():Void {

        // Should remove heads that are not occupied by their owner

        var killHeadsRule:KillHeadsRule = new KillHeadsRule();
        state = makeState(TestBoards.emptyPetri, 4, cast [killHeadsRule]);

        // Change occupier of current player's head

        var head_:AspectPtr = state.playerAspectLookup[BodyAspect.HEAD.id];
        var currentPlayer_:AspectPtr = state.stateAspectLookup[PlyAspect.CURRENT_PLAYER.id];
        var occupier_:AspectPtr = state.nodeAspectLookup[OwnershipAspect.OCCUPIER.id];
        var isFilled_:AspectPtr = state.nodeAspectLookup[OwnershipAspect.IS_FILLED.id];
        var freshness_:AspectPtr = state.nodeAspectLookup[FreshnessAspect.FRESHNESS.id];

        var currentPlayer:Int = history.get(state.aspects.at(currentPlayer_));
        var head:Int = history.get(state.players[currentPlayer].at(head_));
        var playerHead:BoardNode = state.nodes[head];

        history.set(playerHead.value.at(occupier_), 1);

        killHeadsRule.update();
        var options:Array<Option> = killHeadsRule.options;
        Assert.isNotNull(options);
        Assert.areEqual(1, options.length);

        killHeadsRule.chooseOption(0);

        head = history.get(state.players[currentPlayer].at(head_));
        Assert.areEqual(-1, head);
    }
}
