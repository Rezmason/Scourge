package net.rezmason.praxis.config;

class Config<Params> {
    public var composition(get, null):Map<String, RuleComposition<Params>>;
    public var defaultParams(get, null):Null<Params>;
    public function new() {}
    
    function get_composition():Map<String, RuleComposition<Params>> {
        throw 'Override'; 
        return null;
    }
    
    function get_defaultParams():Null<Params> {
        throw 'Override'; 
        return null;
    }
}
