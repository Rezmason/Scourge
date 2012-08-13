package net.rezmason.scourge.model;

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

    public function addPlayerAspects(hash:IntHash<RuleAspect>):Void {
        // determine whether the required player aspects are present in the hash
        // if one is absent, add it
    }

    public function addGameAspects(hash:IntHash<RuleAspect>):Void {
        // determine whether the required game aspects are present in the hash
        // if one is absent, add it
    }

    public function addCellAspects(hash:IntHash<RuleAspect>):Void {
        // determine whether the required cell aspects are present in the hash
        // if one is absent, add it
    }
}

