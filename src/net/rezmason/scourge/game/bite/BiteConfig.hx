package net.rezmason.scourge.game.bite;

import net.rezmason.scourge.game.ConfigTypes;

class BiteConfig extends ScourgeConfig<BiteParams> {

    override function get_composition():Map<String, ScourgeRuleComposition<BiteParams>> {
        return [
            'bite' => {def:BiteRule, type:Action(null), presenter:null, isIncluded:function(p) return p.allowBiting},
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
