package net.rezmason.scourge.game.body;

import net.rezmason.praxis.config.Config;
import net.rezmason.praxis.config.RuleComposition;

class BodyConfig<RP, MP> extends Config<BodyParams, RP, MP> {

    override public function composition():Map<String, RuleComposition<BodyParams, RP, MP>> {
        return [
            'cavity'    => {def:CavityRule,     type:Simple, presenter:null, 
                isIncluded:function(p) return p.includeCavities
            },
            'decay'     => {def:DecayRule,      type:Simple, presenter:null},
            'eatCells'  => {def:EatCellsRule,   type:Simple, presenter:null},
        ];
    }

    override public function defaultParams():Null<BodyParams> {
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
