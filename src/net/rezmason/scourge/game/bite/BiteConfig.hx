package net.rezmason.scourge.game.bite;

import net.rezmason.praxis.config.Config;
import net.rezmason.praxis.config.RuleComposition;

class BiteConfig<RP, MP> extends Config<BiteParams, RP, MP> {

    override public function composition():Map<String, RuleComposition<BiteParams, RP, MP>> {
        return [
            'bite' => {def:BiteRule, type:Action(null), presenter:null, isIncluded:function(p) return p.allowBiting},
        ];
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

            allowBiting:true,
        };
    }
}