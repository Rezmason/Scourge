package net.rezmason.scourge.model;

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

    override public function prime(state:State, plan:StatePlan):Void { for (rule in rules) rule.prime(state, plan); }
    override public function init():Void { for (rule in rules) rule.init(); }

    override public function update():Void {
        rules[0].update();
        options = rules[0].options;
        quantumOptions = rules[0].quantumOptions;
    }

    override public function chooseOption(choice:Int):Void {
        rules[0].chooseOption(choice);
        for (ike in 1...rules.length) {
            var rule:Rule = rules[ike];
            rule.update();
            rule.chooseOption(0);
        }
    }

    override public function chooseQuantumOption(choice:Int):Void {
        rules[0].chooseQuantumOption(choice);
        for (ike in 1...rules.length) {
            var rule:Rule = rules[ike];
            rule.update();
            rule.chooseOption(0);
        }
    }
}

