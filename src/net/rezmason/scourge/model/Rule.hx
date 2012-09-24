package net.rezmason.scourge.model;

import net.rezmason.scourge.model.ModelTypes;

using net.rezmason.utils.Pointers;

class Rule {

    var state:State;
    var plan:StatePlan;

    public var options(default, null):Array<Option>;
    public var quantumOptions(default, null):Array<QuantumOption>;
    public var stateAspectRequirements(default, null):AspectRequirements;
    public var playerAspectRequirements(default, null):AspectRequirements;
    public var nodeAspectRequirements(default, null):AspectRequirements;
    public var extraAspectRequirements(default, null):AspectRequirements;

    private var extraAspectTemplate:AspectSet;
    private var extraAspectLookup:AspectLookup;

    public function new():Void {
        stateAspectRequirements = [];
        playerAspectRequirements = [];
        nodeAspectRequirements = [];
        extraAspectRequirements = [];
        extraAspectTemplate = [];
        extraAspectLookup = [];
        options = [];
        quantumOptions = [];
        __initReqs();
    }

    public function init(state:State, plan:StatePlan):Void {
        this.state = state;
        this.plan = plan;

        for (ike in 0...extraAspectRequirements.length) {
            var prop:AspectProperty = extraAspectRequirements[ike];
            extraAspectLookup[prop.id] = ike.pointerArithmetic();
            extraAspectTemplate[ike] = prop.initialValue;
        }
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

    inline function buildAspectSet(template:AspectSet):AspectSet {
        var aspects:AspectSet = new AspectSet();
        for (val in template) aspects.push(val);
        return aspects;
    }

    inline function buildHistAspectSet(template:AspectSet, history:StateHistory):AspectSet {
        var aspects:AspectSet = new AspectSet();
        for (val in template) aspects.push(history.alloc(val));
        return aspects;
    }

    inline function buildExtra():AspectSet {
        return buildAspectSet(extraAspectTemplate);
    }

    inline function buildHistExtra(history:StateHistory):AspectSet {
        return buildHistAspectSet(extraAspectTemplate, history);
    }

    // Are these still necessary?
    inline function statePtr(prop:AspectProperty):AspectPtr { return plan.stateAspectLookup[prop.id]; }
    inline function playerPtr(prop:AspectProperty):AspectPtr { return plan.playerAspectLookup[prop.id]; }
    inline function nodePtr(prop:AspectProperty):AspectPtr { return plan.nodeAspectLookup[prop.id]; }
    inline function extraPtr(prop:AspectProperty):AspectPtr { return extraAspectLookup[prop.id]; }
}

