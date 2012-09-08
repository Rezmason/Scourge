package net.rezmason.scourge.model;

import net.rezmason.scourge.model.ModelTypes;

class Rule {

    /*
    Rules can be chained
        BiteDecayRule
        SwapSkipRule
        SkipForfeitRule
        DropEatDecaySkipRule
    */

    var state:State;
    var history:StateHistory;

    public var options(default, null):Array<Option>;
    public var stateAspectRequirements(default, null):AspectRequirements;
    public var playerAspectRequirements(default, null):AspectRequirements;
    public var nodeAspectRequirements(default, null):AspectRequirements;

    public function new():Void {
        stateAspectRequirements = [];
        playerAspectRequirements = [];
        nodeAspectRequirements = [];
        options = [];
    }

    public function init(state:State):Void {
        this.state = state;
        history = state.history;
    }

    public function update():Void {

    }

    public function chooseOption(choice:Int):Void { }
}

