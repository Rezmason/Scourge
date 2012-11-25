package net.rezmason.scourge.model.rules;

import net.rezmason.scourge.model.aspects.BodyAspect;
import net.rezmason.scourge.model.aspects.FreshnessAspect;
import net.rezmason.scourge.model.aspects.PlyAspect;

using Lambda;

//using net.rezmason.scourge.model.GridUtils;
using net.rezmason.utils.Pointers;

class EndTurnRule extends Rule {

    @player(BodyAspect.HEAD) var head_;
    @player(FreshnessAspect.FRESHNESS) var freshness_;
    @state(FreshnessAspect.MAX_FRESHNESS) var maxFreshness_;
    @state(PlyAspect.CURRENT_PLAYER) var currentPlayer_;

    public function new():Void {
        super();
        options.push({optionID:0});
    }

    override public function chooseOption(choice:Int = 0):Void {
        super.chooseOption(choice);

        // Get current player

        var currentPlayer:Int = state.aspects.at(currentPlayer_);
        var numPlayers:Int = state.players.length;

        // Find the next living player
        var playerIndex:Int = (currentPlayer + 1) % numPlayers;
        while (state.players[playerIndex].at(head_) == Aspect.NULL) {
            playerIndex = (playerIndex + 1) % numPlayers;
            if (playerIndex == currentPlayer) throw "No players have heads!";
        }

        // reset freshness on all nodes
        for (node in state.nodes) node.value.mod(freshness_, 0);

        state.aspects.mod(currentPlayer_, playerIndex);
        state.aspects.mod(maxFreshness_, 0);
    }
}

