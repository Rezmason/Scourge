package net.rezmason.scourge.game.body;

import net.rezmason.scourge.game.ConfigTypes;


class BodyConfig extends ScourgeConfig<BodyParams> {

    override function get_composition():Map<String, ScourgeRuleComposition<BodyParams>> {
        return [
            'cavity'    => {def:CavityRule,     type:Simple, presenter:null, 
                isIncluded:function(p) return p.includeCavities
            },
            'decay'     => {def:DecayRule,      type:Simple, presenter:null},
            'eatCells'  => {def:EatCellsRule,   type:Simple, presenter:null},
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
