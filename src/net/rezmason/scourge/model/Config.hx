package net.rezmason.scourge.model;

class Config<Params> {

    public function new() {
        
    }

    public function id():String {
        // throw 'Override';
        return null;
    }

    public function ruleComposition():RuleComposition {
        // throw 'Override';
        return null;
    }

    public function defaultParams():Null<Params> {
        // throw 'Override';
        return null;
    }
}
