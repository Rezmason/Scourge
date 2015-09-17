package net.rezmason.scourge.game.meta;

import net.rezmason.praxis.aspect.Aspect.*;
import net.rezmason.praxis.aspect.WinAspect;
import net.rezmason.praxis.rule.Actor;
import net.rezmason.scourge.game.body.BodyAspect;

class OneLivingPlayerActor extends Actor<Dynamic> {

    @player(BodyAspect.HEAD) var head_;
    @global(WinAspect.WINNER, true) var winner_;

    // This rule discovers whether there is only one remaining player, and makes that player the winner
    override public function chooseMove(_):Void {

        var playersWithHeads:Array<Int> = [];
        for (player in eachPlayer()) {
            var headIndex:Int = player[head_];
            if (headIndex != NULL) playersWithHeads.push(getID(player));
        }

        if (playersWithHeads.length == 1) state.global[winner_] = playersWithHeads.pop();
    }
}

