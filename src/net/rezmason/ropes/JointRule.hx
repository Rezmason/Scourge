package net.rezmason.ropes;

using net.rezmason.utils.ArrayUtils;

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
        options = rules[0].options;
        quantumOptions = rules[0].quantumOptions;
    }

    override private function _chooseOption(choice:Int):Void {
        #if ROPES_VERBOSE trace("{"); #end

        rules[0].chooseOption(choice);
        for (ike in 1...rules.length) {
            var rule:Rule = rules[ike];
            rule.update();
            rule.chooseOption();
        }

        #if ROPES_VERBOSE trace("}"); #end
    }

    override private function _chooseQuantumOption(choice:Int):Void {
        #if ROPES_VERBOSE trace("{"); #end

        rules[0].chooseQuantumOption(choice);
        for (ike in 1...rules.length) {
            var rule:Rule = rules[ike];
            rule.update();
            rule.chooseOption();
        }

        #if ROPES_VERBOSE trace("}"); #end
    }
}

