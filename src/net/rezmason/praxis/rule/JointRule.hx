package net.rezmason.praxis.rule;

import net.rezmason.praxis.PraxisTypes;

using net.rezmason.utils.MapUtils;

class JointRule extends BaseRule<Array<Rule>> {

    override private function _init():Void {
        for (rule in params) {
            globalAspectRequirements.absorb(rule.globalAspectRequirements);
            playerAspectRequirements.absorb(rule.playerAspectRequirements);
            nodeAspectRequirements.absorb(rule.nodeAspectRequirements);
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
        #if ROPES_VERBOSE trace('{'); #end

        params[0].chooseMove(choice);
        for (ike in 1...params.length) {
            var rule:Rule = params[ike];
            rule.update();
            rule.chooseMove();
        }

        #if ROPES_VERBOSE trace('}'); #end
    }

    override private function _collectMoves():Void params[0].collectMoves();
}

