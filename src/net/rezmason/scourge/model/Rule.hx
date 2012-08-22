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

    public function new():Void { }

    public function init(state:State) { }

    public function listStateAspectRequirements():AspectRequirements { return null; }
    public function listPlayerAspectRequirements():AspectRequirements { return null; }
    public function listBoardAspectRequirements():AspectRequirements { return null; }

    public function getOptions(state:State):Array<Option> { return null; }
    public function chooseOption(state:State, option:Option):Void { }
}

