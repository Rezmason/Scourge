package net.rezmason.ropes;

import net.rezmason.ropes.RopesTypes;

class JointRule extends RopesRule<Array<Rule>> {

    override private function _update():Void {
        params[0].update();
        moves = params[0].moves;
        quantumMoves = params[0].quantumMoves;
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

    override private function _chooseQuantumMove(choice:Int):Void {
        #if ROPES_VERBOSE trace('{'); #end

        params[0].chooseQuantumMove(choice);
        for (ike in 1...params.length) {
            var rule:Rule = params[ike];
            rule.update();
            rule.chooseMove();
        }

        #if ROPES_VERBOSE trace('}'); #end
    }
}

