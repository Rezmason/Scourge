package net.rezmason.scourge.model.rules;

import net.rezmason.ropes.Aspect;
import net.rezmason.ropes.Rule;
import net.rezmason.scourge.model.aspects.BodyAspect;
import net.rezmason.scourge.model.aspects.WinAspect;

using net.rezmason.utils.Pointers;

class OneLivingPlayerRule extends Rule {

    @player(BodyAspect.HEAD) var head_;
    @state(WinAspect.WINNER) var winner_;

    // This rule discovers whether there is only one remaining player, and makes that player the winner
    public function new():Void {
        super();
        options.push({optionID:0});
    }

    override private function _chooseOption(choice:Int):Void {

        var playersWithHeads:Array<Int> = [];
        for (ike in 0...state.players.length) {
            var headIndex:Int = state.players[ike].at(head_);
            if (headIndex != Aspect.NULL) playersWithHeads.push(ike);
        }

        if (playersWithHeads.length == 1) state.aspects.mod(winner_, playersWithHeads.pop());
    }
}

