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

    public var id(default, null):String;

    public function createPlayerAspect():RuleAspect {
        // The object used by this rule to represent the state of a player
        return null;
    }

    public function createGameAspect():RuleAspect {
        // The object used by this rule to represent the state of a game
        return null;
    }

    // Handy tip: Reflect has a copy() function for anonymous objects
}

