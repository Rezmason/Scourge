package net.rezmason.scourge.model;

import massive.munit.Assert;

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
        history.set(state.players[3].at(head_), Aspect.NULL);


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

        //trace(state.spitBoard());
        forfeitRule.chooseOption(0);
        //trace(state.spitBoard());

        Assert.areEqual(Aspect.NULL, history.get(playerHead.value.at(occupier_)));
        Assert.areEqual(0, history.get(playerHead.value.at(isFilled_)));

        // Player 1 should be gone
        var numCells:Int = ~/([^0])/g.replace(state.spitBoard(), "").length;
        Assert.areEqual(0, numCells);

        var bodyFirst_:AspectPtr = state.playerAspectLookup[BodyAspect.BODY_FIRST.id];
        Assert.areEqual(Aspect.NULL, history.get(state.players[currentPlayer].at(bodyFirst_)));
    }

    @Test
    public function killHeadsTest():Void {

        // Should remove heads that are not occupied by their owner

        var killHeadlessPlayerRule:KillHeadlessPlayerRule = new KillHeadlessPlayerRule();
        state = makeState(TestBoards.emptyPetri, 4, cast [killHeadlessPlayerRule]);

        // Change occupier of current player's head

        var head_:AspectPtr = state.playerAspectLookup[BodyAspect.HEAD.id];
        var currentPlayer_:AspectPtr = state.stateAspectLookup[PlyAspect.CURRENT_PLAYER.id];
        var occupier_:AspectPtr = state.nodeAspectLookup[OwnershipAspect.OCCUPIER.id];
        var isFilled_:AspectPtr = state.nodeAspectLookup[OwnershipAspect.IS_FILLED.id];
        var freshness_:AspectPtr = state.nodeAspectLookup[FreshnessAspect.FRESHNESS.id];
        var bodyFirst_:AspectPtr = state.playerAspectLookup[BodyAspect.BODY_FIRST.id];

        var currentPlayer:Int = history.get(state.aspects.at(currentPlayer_));
        var head:Int = history.get(state.players[currentPlayer].at(head_));
        var playerHead:BoardNode = state.nodes[head];

        history.set(playerHead.value.at(occupier_), 1);

        killHeadlessPlayerRule.update();
        var options:Array<Option> = killHeadlessPlayerRule.options;
        Assert.isNotNull(options);
        Assert.areEqual(1, options.length);

        killHeadlessPlayerRule.chooseOption(0);

        head = history.get(state.players[currentPlayer].at(head_));
        Assert.areEqual(Aspect.NULL, head);

        var bodyFirst:Int = history.get(state.players[currentPlayer].at(bodyFirst_));
        Assert.areEqual(Aspect.NULL, bodyFirst);
    }
}
