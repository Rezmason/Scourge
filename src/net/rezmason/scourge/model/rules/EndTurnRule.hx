package net.rezmason.scourge.model.rules;

import net.rezmason.ropes.Aspect;
import net.rezmason.ropes.Rule;
import net.rezmason.scourge.model.aspects.BodyAspect;
import net.rezmason.scourge.model.aspects.FreshnessAspect;
import net.rezmason.scourge.model.aspects.PlyAspect;

using Lambda;

//using net.rezmason.ropes.GridUtils;
using net.rezmason.utils.Pointers;

class EndTurnRule extends Rule {

    @player(BodyAspect.HEAD) var head_;
    @node(FreshnessAspect.FRESHNESS) var freshness_;
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
        var startPlayerIndex:Int = (currentPlayer + 1) % numPlayers;
        var playerIndex:Int = startPlayerIndex;
        while (state.players[playerIndex].at(head_) == Aspect.NULL) {
            playerIndex = (playerIndex + 1) % numPlayers;
            if (playerIndex == startPlayerIndex) throw "No players have heads!";
        }

        // reset freshness on all nodes
        for (node in state.nodes) node.value.mod(freshness_, 0);

        state.aspects.mod(currentPlayer_, playerIndex);
        state.aspects.mod(maxFreshness_, 0);
    }
}

