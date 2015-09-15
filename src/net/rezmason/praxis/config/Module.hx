package net.rezmason.praxis.config;

class Module<Params> {
    public function new() {}
    public function composeRules():Map<String, RuleComposition<Params>> return null;
    public function makeDefaultParams():Null<Params> return null;
}
