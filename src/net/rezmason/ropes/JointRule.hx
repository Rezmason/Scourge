package net.rezmason.ropes;

using net.rezmason.utils.MapUtils;

class JointRule extends Rule {

    var rules:Array<Rule>;

    public function new(rules:Array<Rule>):Void {
        super();
        this.rules = rules;

        for (rule in rules) {
            stateAspectRequirements.absorb(rule.stateAspectRequirements);
            playerAspectRequirements.absorb(rule.playerAspectRequirements);
            nodeAspectRequirements.absorb(rule.nodeAspectRequirements);
        }
    }

    override private function _update():Void {
        rules[0].update();
        moves = rules[0].moves;
        quantumMoves = rules[0].quantumMoves;
    }

    override private function _chooseMove(choice:Int):Void {
        #if ROPES_VERBOSE trace('{'); #end

        rules[0].chooseMove(choice);
        for (ike in 1...rules.length) {
            var rule:Rule = rules[ike];
            rule.update();
            rule.chooseMove();
        }

        #if ROPES_VERBOSE trace('}'); #end
    }

    override private function _chooseQuantumMove(choice:Int):Void {
        #if ROPES_VERBOSE trace('{'); #end

        rules[0].chooseQuantumMove(choice);
        for (ike in 1...rules.length) {
            var rule:Rule = rules[ike];
            rule.update();
            rule.chooseMove();
        }

        #if ROPES_VERBOSE trace('}'); #end
    }
}

