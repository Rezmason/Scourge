package net.rezmason.scourge.game.body;

import net.rezmason.praxis.config.Module;
import net.rezmason.praxis.config.RuleComposition;

#if !HEADLESS
    import net.rezmason.scourge.controller.CavityRulePresenter;
    import net.rezmason.scourge.controller.DecayRulePresenter;
    import net.rezmason.scourge.controller.EatRulePresenter;
#end

class BodyModule extends Module<BodyParams> {

    override public function composeRules():Map<String, RuleComposition<BodyParams>> {
        return [
            'cavity' => {type:Simple(new CavityActor(), #if HEADLESS null #else new CavityRulePresenter() #end),
                isIncluded:function(p) return p.includeCavities
            },
            'decay'  => {type:Simple(new DecayActor(), #if HEADLESS null #else new DecayRulePresenter() #end)},
            'eat'    => {type:Simple(new EatActor(), #if HEADLESS null #else new EatRulePresenter() #end)},
        ];
    }

    override public function makeDefaultParams() {
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
