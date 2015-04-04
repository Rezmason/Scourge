package net.rezmason.scourge.game.meta;

import net.rezmason.praxis.aspect.Aspect.*;
import net.rezmason.praxis.aspect.WinAspect;
import net.rezmason.praxis.rule.BaseRule;
import net.rezmason.scourge.game.body.BodyAspect;

using net.rezmason.utils.Pointers;

class OneLivingPlayerRule extends BaseRule<Dynamic> {

    @player(BodyAspect.HEAD) var head_;
    @global(WinAspect.WINNER) var winner_;

    // This rule discovers whether there is only one remaining player, and makes that player the winner
    override private function _chooseMove(choice:Int):Void {

        var playersWithHeads:Array<Int> = [];
        for (player in eachPlayer()) {
            var headIndex:Int = player[head_];
            if (headIndex != NULL) playersWithHeads.push(getID(player));
        }

        if (playersWithHeads.length == 1) state.global[winner_] = playersWithHeads.pop();
    }
}

