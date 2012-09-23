package net.rezmason.scourge.model;

import net.rezmason.scourge.model.ModelTypes;

class Rule {

    var state:State;
    var plan:StatePlan;

    public var options(default, null):Array<Option>;
    public var quantumOptions(default, null):Array<QuantumOption>;
    public var stateAspectRequirements(default, null):AspectRequirements;
    public var playerAspectRequirements(default, null):AspectRequirements;
    public var nodeAspectRequirements(default, null):AspectRequirements;

    public function new():Void {
        stateAspectRequirements = [];
        playerAspectRequirements = [];
        nodeAspectRequirements = [];
        options = [];
        quantumOptions = [];
        __initReqs();
    }

    public function init(state:State, plan:StatePlan):Void {
        this.state = state;
        this.plan = plan;
        __initPtrs();
    }

    private function __initReqs():Void {}
    private function __initPtrs():Void {}

    public function update():Void {}

    public function chooseOption(choice:Int):Void {
        if (options == null || options.length < choice || options[choice] == null) {
            throw "Invalid choice index.";
        }
    }

    public function chooseQuantumOption(choice:Int):Void {
        if (quantumOptions == null || quantumOptions.length < choice || quantumOptions[choice] == null) {
            throw "Invalid choice index.";
        }
    }

    private function boom():Void {}

    inline function statePtr(prop:AspectProperty):AspectPtr { return plan.stateAspectLookup[prop.id]; }
    inline function playerPtr(prop:AspectProperty):AspectPtr { return plan.playerAspectLookup[prop.id]; }
    inline function nodePtr(prop:AspectProperty):AspectPtr { return plan.nodeAspectLookup[prop.id]; }
}

