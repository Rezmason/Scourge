package net.rezmason.scourge.model;

import net.rezmason.scourge.model.ModelTypes;

class Rule {

    /*
    a generator whose input and output are a State and a set of States that can be reached from that State
    Organized hierarchically based on the parameters of the action associated with the IRule
        Each param must be easily converted to String
            Commands are URLs, basically
    Rules can be chained
        BiteDecayRule
        SwapSkipRule
        SkipForfeitRule
        DropEatDecaySkipRule
    TestRule
    Command validation
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
    public function chooseOption(option:Option):Void { }
}

