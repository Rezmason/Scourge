package net.rezmason.praxis.rule;

import net.rezmason.praxis.PraxisTypes;
import net.rezmason.praxis.rule.BaseRule;

using net.rezmason.utils.MapUtils;

class JointRule extends BaseRule<Array<BaseRule<Dynamic>>> {

    override private function _init():Void {
        for (rule in params) {
            globalAspectRequirements.absorb(rule.globalAspectRequirements);
            playerAspectRequirements.absorb(rule.playerAspectRequirements);
            cardAspectRequirements.absorb(rule.cardAspectRequirements);
            spaceAspectRequirements.absorb(rule.spaceAspectRequirements);
        }
        isRandom = params[0].isRandom;
    }

    override private function _update():Void {
        params[0].update();
        moves = params[0].moves;
    }

    override public function _prime():Void {
        for (rule in params) if (!rule.primed) rule.prime(state, plan, history, historyState, changeSignal);
    }

    override private function _chooseMove(choice:Int):Void {
        #if PRAXIS_VERBOSE trace('{'); #end

        params[0].chooseMove(choice);
        for (ike in 1...params.length) {
            var rule:BaseRule<Dynamic> = params[ike];
            rule.update();
            rule.chooseMove();
        }

        #if PRAXIS_VERBOSE trace('}'); #end
    }

    override private function _collectMoves():Void params[0].collectMoves();
}

