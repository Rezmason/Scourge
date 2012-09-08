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

    public function new():Void { }

    public function init(state:State) {
        this.state = state;
        history = state.history;
    }

    public function listStateAspectRequirements():AspectRequirements { return []; }
    public function listPlayerAspectRequirements():AspectRequirements { return []; }
    public function listBoardAspectRequirements():AspectRequirements { return []; }

    public function getOptions():Array<Option> { return []; }
    public function chooseOption(choice:Int):Void { }
}

