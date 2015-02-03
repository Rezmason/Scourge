package net.rezmason.scourge.model.meta;

import net.rezmason.ropes.Aspect.*;
import net.rezmason.ropes.RopesRule;
import net.rezmason.scourge.model.body.BodyAspect;

using net.rezmason.utils.Pointers;

typedef SkipsExhaustedParams = {
    var maxSkips:Int;
}

class StalemateRule extends RopesRule<SkipsExhaustedParams> {

    @player(BodyAspect.TOTAL_AREA) var totalArea_;
    @player(SkipAspect.NUM_CONSECUTIVE_SKIPS) var numConsecutiveSkips_;
    @global(WinAspect.WINNER) var winner_;

    // This rule discovers whether there is only one remaining player, and makes that player the winner
    override private function _chooseMove(choice:Int):Void {

        var stalemate:Bool = true;

        if (state.global[winner_] != NULL) {
            stalemate = false;
        } else {
            for (player in eachPlayer()) {
                if (player[numConsecutiveSkips_] < params.maxSkips) {
                    stalemate = false;
                    break;
                }
            }
        }

        var largestArea:Int = -1;
        var largestPlayers:Array<Int> = null;

        if (stalemate) {
            for (player in eachPlayer()) {
                var playerID:Int = getID(player);
                var totalArea:Int = player[totalArea_];

                if (totalArea > largestArea) largestPlayers = [playerID];
                else if (totalArea == largestArea) largestPlayers.push(playerID);
            }

            state.global[winner_] = largestPlayers.pop();
            signalChange();
        }
    }
}

