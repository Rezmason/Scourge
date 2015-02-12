package net.rezmason.praxis.config;

class Config<Params, RP, MP> {
    public function new() {}
    
    public function composition():Map<String, RuleComposition<Params, RP, MP>> {
        throw 'Override'; 
        return null;
    }
    
    public function defaultParams():Null<Params> {
        throw 'Override'; 
        return null;
    }
}
