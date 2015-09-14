package net.rezmason.scourge.game.bite;

import net.rezmason.praxis.config.Config;
import net.rezmason.praxis.config.RuleComposition;

class BiteConfig extends Config<BiteParams> {

    override function get_composition():Map<String, RuleComposition<BiteParams>> {
        return [
            'bite' => {type:Action(new BiteRule(), null, null, null), isIncluded:function(p) return p.allowBiting},
        ];
    }

    override function get_defaultParams() {
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
