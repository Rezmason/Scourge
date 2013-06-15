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
        moves.push({id:0});
    }

    override private function _chooseMove(choice:Int):Void {

        // Get current player

        var currentPlayer:Int = state.aspects.at(currentPlayer_);

        // Find the next living player
        var startPlayerIndex:Int = (currentPlayer + 1) % numPlayers();
        var playerID:Int = startPlayerIndex;
        while (getPlayer(playerID).at(head_) == Aspect.NULL) {
            playerID = (playerID + 1) % numPlayers();
            if (playerID == startPlayerIndex) throw 'No players have heads!';
        }

        // reset freshness on all nodes
        for (node in eachNode()) node.value.mod(freshness_, 0);

        state.aspects.mod(currentPlayer_, playerID);
        state.aspects.mod(maxFreshness_, 0);
    }
}

