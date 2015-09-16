package net.rezmason.scourge.game.bite;

import net.rezmason.praxis.config.Module;
import net.rezmason.praxis.config.RuleComposition;

class BiteModule extends Module<BiteParams> {

    override public function composeRules():Map<String, RuleComposition<BiteParams>> {
        return [
            'bite' => {type:Action(new BiteSurveyor(), new BiteActor(), null, null, null), isIncluded:function(p) return p.allowBiting},
        ];
    }

    override public function makeDefaultParams() {
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
