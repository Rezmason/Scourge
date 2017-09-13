package net.rezmason.scourge.game.bite;

import net.rezmason.praxis.config.Module;
import net.rezmason.praxis.config.RuleComposition;
import net.rezmason.praxis.config.RuleType;

class BiteModule extends Module<BiteParams> {

    override public function composeRules():Map<String, RuleComposition<BiteParams>> {
        var rules:Map<String, RuleComposition<BiteParams>> = new Map();
        rules['bite'] = {
            type:Action(null, new BiteSurveyor(), new BiteActor(), null, null, null), 
            isIncluded:function(p:BiteParams) return p.allowBiting == true,
        };
        return rules;
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
