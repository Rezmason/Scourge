package net.rezmason.scourge.model;

import massive.munit.Assert;

import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.aspects.BodyAspect;
import net.rezmason.scourge.model.aspects.FreshnessAspect;
import net.rezmason.scourge.model.aspects.OwnershipAspect;
import net.rezmason.scourge.model.aspects.PlyAspect;
import net.rezmason.scourge.model.rules.DecayRule;

using net.rezmason.scourge.model.GridUtils;
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
        state = makeState(TestBoards.spiral, 4, cast [decayRule]);

        var occupier_:AspectPtr = state.nodeAspectLookup[OwnershipAspect.OCCUPIER.id];
        var isFilled_:AspectPtr = state.nodeAspectLookup[OwnershipAspect.IS_FILLED.id];
        var freshness_:AspectPtr = state.nodeAspectLookup[FreshnessAspect.FRESHNESS.id];
        var head_:AspectPtr = state.playerAspectLookup[BodyAspect.HEAD.id];
        var currentPlayer_:AspectPtr = state.stateAspectLookup[PlyAspect.CURRENT_PLAYER.id];

        var numCells:Int = ~/([^0])/g.replace(TestBoards.spiral, "").length;
        Assert.areEqual(51, numCells); // 51 cells for player 0

        var currentPlayer:Int = history.get(state.aspects.at(currentPlayer_));

        var head:Int = history.get(state.players[currentPlayer].at(head_));
        var playerHead:BoardNode = state.nodes[head];
        var playerNeck:BoardNode = playerHead.n();

        // Cut the neck

        history.set(playerNeck.value.at(isFilled_), 0);
        history.set(playerNeck.value.at(occupier_), -1);
        history.set(playerNeck.value.at(freshness_), 1);

        //Pass the State to the Rule for Option generation

        decayRule.update();
        var options:Array<Option> = decayRule.options;

        Assert.isNotNull(options);
        Assert.areEqual(1, options.length);

        //trace(BoardUtils.spitBoard(state));
        decayRule.chooseOption(0);
        //trace(BoardUtils.spitBoard(state));

        numCells = ~/([^0])/g.replace(BoardUtils.spitBoard(state), "").length;
        Assert.areEqual(1, numCells); // only one cell for player 0
    }

    @Test
    public function decayRuleTest2():Void {

        var decayRule:DecayRule = new DecayRule();
        state = makeState(TestBoards.spiralPetri, 1, cast [decayRule]);

        var occupier_:AspectPtr = state.nodeAspectLookup[OwnershipAspect.OCCUPIER.id];
        var isFilled_:AspectPtr = state.nodeAspectLookup[OwnershipAspect.IS_FILLED.id];
        var freshness_:AspectPtr = state.nodeAspectLookup[FreshnessAspect.FRESHNESS.id];
        var head_:AspectPtr = state.playerAspectLookup[BodyAspect.HEAD.id];
        var currentPlayer_:AspectPtr = state.stateAspectLookup[PlyAspect.CURRENT_PLAYER.id];

        var numCells:Int = ~/([^0])/g.replace(TestBoards.spiralPetri, "").length;

        Assert.areEqual(17, numCells); // 51 cells for player 0

        var currentPlayer:Int = history.get(state.aspects.at(currentPlayer_));

        var head:Int = history.get(state.players[currentPlayer].at(head_));
        var playerHead:BoardNode = state.nodes[head];
        var playerNeck:BoardNode = playerHead.s();

        // Cut the neck

        history.set(playerNeck.value.at(isFilled_), 0);
        history.set(playerNeck.value.at(occupier_), -1);
        history.set(playerNeck.value.at(freshness_), 1);

        //trace(BoardUtils.spitBoard(state));
        decayRule.chooseOption(0);
        //trace(BoardUtils.spitBoard(state));

        numCells = ~/([^0])/g.replace(BoardUtils.spitBoard(state), "").length;
        Assert.areEqual(1, numCells); // only one cell for player 0
    }
}
