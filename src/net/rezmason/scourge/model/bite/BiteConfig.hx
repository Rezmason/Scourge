package net.rezmason.scourge.model.bite;

class BiteConfig extends Config<BiteParams> {

    override public function id():String {
        return 'bite';
    }

    public override function ruleComposition():RuleComposition {
        return null;
    }

    override public function defaultParams():Null<BiteParams> {
        return {
            minReach: 1,
            maxReach: 3,
            maxSizeReference: Std.int(400 * 0.7),
            baseReachOnThickness: false,
            omnidirectional: false,
            biteThroughCavities: false,
            biteHeads: true,
            orthoOnly: true,
            startingBites: 5,
        };
    }
}
