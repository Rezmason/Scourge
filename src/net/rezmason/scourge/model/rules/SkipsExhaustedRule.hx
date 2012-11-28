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

class SkipsExhaustedRule extends Rule {

    @player(BodyAspect.TOTAL_AREA) var totalArea_;
    @player(PlyAspect.NUM_CONSECUTIVE_SKIPS) var numConsecutiveSkips_;
    @state(WinAspect.WINNER) var winner_;

    private var cfg:SkipsExhaustedConfig;

    // This rule discovers whether there is only one remaining player, and makes that player the winner
    public function new(cfg:SkipsExhaustedConfig):Void {
        super();
        this.cfg = cfg;
        options.push({optionID:0});
    }

    override public function chooseOption(choice:Int = 0):Void {
        super.chooseOption(choice);

        var stalemate:Bool = true;

        if (state.aspects.at(winner_) != Aspect.NULL) {
            stalemate = false;
        } else {
            for (player in state.players) {
                if (player.at(numConsecutiveSkips_) < cfg.maxSkips) {
                    stalemate = false;
                    break;
                }
            }
        }

        var largestArea:Int = -1;
        var largestPlayers:Array<Int> = null;

        if (stalemate) {
            for (ike in 0...state.players.length) {
                var totalArea:Int = state.players[ike].at(totalArea_);
                if (totalArea > largestArea) largestPlayers = [ike];
                else if (totalArea == largestArea) largestPlayers.push(ike);
            }

            state.aspects.mod(winner_, largestPlayers.pop());
        }
    }
}

