package net.rezmason.scourge.game.body;

import net.rezmason.praxis.config.Config;
import net.rezmason.praxis.config.RuleComposition;

#if !HEADLESS
    import net.rezmason.scourge.controller.CavityRulePresenter;
    import net.rezmason.scourge.controller.DecayRulePresenter;
    import net.rezmason.scourge.controller.EatRulePresenter;
#end

class BodyConfig extends Config<BodyParams> {

    override function get_composition():Map<String, RuleComposition<BodyParams>> {
        return [
            'cavity' => {type:Simple(new CavityRule(), #if HEADLESS null #else new CavityRulePresenter() #end),
                isIncluded:function(p) return p.includeCavities
            },
            'decay'  => {type:Simple(new DecayRule(), #if HEADLESS null #else new DecayRulePresenter() #end)},
            'eat'    => {type:Simple(new EatRule(), #if HEADLESS null #else new EatRulePresenter() #end)},
        ];
    }

    override function get_defaultParams() {
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
