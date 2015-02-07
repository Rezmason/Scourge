package net.rezmason.scourge.model.meta;

class MetaConfig extends Config<MetaParams> {

    override public function id():String {
        return 'meta';
    }

    public override function ruleComposition():RuleComposition {
        return null;
    }

    override public function defaultParams():Null<MetaParams> {
        return {
            maxSkips: 3,
            playerProperties: new Map(),
            nodeProperties: new Map(),
            globalProperties: new Map(),
        };
    }
}
