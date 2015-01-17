package net.rezmason.ropes;

import net.rezmason.ropes.RopesTypes;

class JointRule extends RopesRule<Array<Rule>> {

    override private function _update():Void {
        config[0].update();
        moves = config[0].moves;
        quantumMoves = config[0].quantumMoves;
    }

    override private function _chooseMove(choice:Int):Void {
        #if ROPES_VERBOSE trace('{'); #end

        config[0].chooseMove(choice);
        for (ike in 1...config.length) {
            var rule:Rule = config[ike];
            rule.update();
            rule.chooseMove();
        }

        #if ROPES_VERBOSE trace('}'); #end
    }

    override private function _collectMoves():Void config[0].collectMoves();

    override private function _chooseQuantumMove(choice:Int):Void {
        #if ROPES_VERBOSE trace('{'); #end

        config[0].chooseQuantumMove(choice);
        for (ike in 1...config.length) {
            var rule:Rule = config[ike];
            rule.update();
            rule.chooseMove();
        }

        #if ROPES_VERBOSE trace('}'); #end
    }
}

