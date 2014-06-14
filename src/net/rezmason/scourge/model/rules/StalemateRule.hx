package net.rezmason.scourge.model.rules;

import net.rezmason.ropes.Aspect;
import net.rezmason.ropes.Rule;
import net.rezmason.scourge.model.aspects.BodyAspect;
import net.rezmason.scourge.model.aspects.PlyAspect;
import net.rezmason.scourge.model.aspects.WinAspect;

using net.rezmason.utils.Pointers;

typedef SkipsExhaustedConfig = {
    var maxSkips:Int;
}

class StalemateRule extends Rule {

    @player(BodyAspect.TOTAL_AREA) var totalArea_;
    @player(PlyAspect.NUM_CONSECUTIVE_SKIPS) var numConsecutiveSkips_;
    @global(WinAspect.WINNER) var winner_;

    private var cfg:SkipsExhaustedConfig;

    // This rule discovers whether there is only one remaining player, and makes that player the winner
    override public function _init(cfg:Dynamic):Void {
        this.cfg = cfg;
        moves.push({id:0});
    }

    override private function _chooseMove(choice:Int):Void {

        var stalemate:Bool = true;

        if (state.globals[winner_] != Aspect.NULL) {
            stalemate = false;
        } else {
            for (player in eachPlayer()) {
                if (player[numConsecutiveSkips_] < cfg.maxSkips) {
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

            state.globals[winner_] = largestPlayers.pop();
            signalEvent();
        }
    }
}

