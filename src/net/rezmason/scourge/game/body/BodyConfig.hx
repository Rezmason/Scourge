package net.rezmason.scourge.game.body;

import net.rezmason.scourge.game.ConfigTypes;

#if !HEADLESS
    import net.rezmason.scourge.controller.CavityRulePresenter;
    import net.rezmason.scourge.controller.DecayRulePresenter;
    import net.rezmason.scourge.controller.EatCellsRulePresenter;
#end

class BodyConfig extends ScourgeConfig<BodyParams> {

    override function get_composition():Map<String, ScourgeRuleComposition<BodyParams>> {
        return [
            'cavity'    => {def:CavityRule,     type:Simple, presenter:#if HEADLESS null #else CavityRulePresenter #end,
                isIncluded:function(p) return p.includeCavities
            },
            'decay'     => {def:DecayRule,      type:Simple, presenter:#if HEADLESS null #else DecayRulePresenter #end},
            'eatCells'  => {def:EatCellsRule,   type:Simple, presenter:#if HEADLESS null #else EatCellsRulePresenter #end},
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
