package net.rezmason.scourge.model.rules;

import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.aspects.BodyAspect;
import net.rezmason.scourge.model.aspects.FreshnessAspect;
import net.rezmason.scourge.model.aspects.PlyAspect;

using Lambda;

//using net.rezmason.scourge.model.GridUtils;
using net.rezmason.utils.Pointers;

class EndTurnRule extends Rule {

    var head_:AspectPtr;
    var currentPlayer_:AspectPtr;
    var maxFreshness_:AspectPtr;

    public function new():Void {
        super();

        stateAspectRequirements = [
            PlyAspect.CURRENT_PLAYER,
            FreshnessAspect.MAX_FRESHNESS,
        ];

        playerAspectRequirements = [
            BodyAspect.HEAD,
        ];

        options.push({optionID:0});
    }

    override public function init(state:State, plan:StatePlan):Void {
        super.init(state, plan);
        head_ = plan.playerAspectLookup[BodyAspect.HEAD.id];
        currentPlayer_ = plan.stateAspectLookup[PlyAspect.CURRENT_PLAYER.id];
        maxFreshness_ = plan.stateAspectLookup[FreshnessAspect.MAX_FRESHNESS.id];
    }

    override public function chooseOption(choice:Int):Void {
        super.chooseOption(choice);

        // Get current player

        var currentPlayer:Int = state.aspects.at(currentPlayer_);
        var numPlayers:Int = state.players.length;

        var playerIndex:Int = (currentPlayer + 1) % numPlayers;

        while (state.players[playerIndex].at(head_) == Aspect.NULL) {
            playerIndex = (playerIndex + 1) % numPlayers;
            if (playerIndex == currentPlayer) throw "No players have heads!";
        }

        state.aspects.mod(currentPlayer_, playerIndex);
        state.aspects.mod(maxFreshness_, 0);
    }
}

