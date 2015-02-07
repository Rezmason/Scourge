package net.rezmason.scourge.model.body;

class BodyConfig extends Config<BodyParams> {

    override public function id():String {
        return 'body';
    }

    public override function ruleComposition():RuleComposition {
        return null;
    }

    override public function defaultParams():Null<BodyParams> {
        return {
            eatRecursively:true,
            eatHeads:true,
            takeBodiesFromEatenHeads:true,
            eatOrthogonallyOnly:false,
            decayOrthogonallyOnly:true,

            includeCavities:true,
        };
    }
}
