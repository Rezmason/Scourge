package net.rezmason.scourge.model;

import net.rezmason.scourge.model.aspects.Aspect;

typedef AspectList = IntHash<Class<Aspect>>;

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

    public function listStateAspects():AspectList { return null; }
    public function listPlayerAspects():AspectList { return null; }
    public function listBoardAspects():AspectList { return null; }
}

