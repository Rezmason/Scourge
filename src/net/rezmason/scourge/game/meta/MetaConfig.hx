package net.rezmason.scourge.game.meta;

import net.rezmason.praxis.config.Config;
import net.rezmason.praxis.config.RuleComposition;

class MetaConfig<RP, MP> extends Config<MetaParams, RP, MP> {

    override public function composition():Map<String, RuleComposition<MetaParams, RP, MP>> {
        return [
            'endTurn'           => {def:EndTurnRule,            type:Simple,       presenter:null},
            'forfeit'           => {def:ForfeitRule,            type:Action(null), presenter:null},
            'killHeadlessBody'  => {def:KillHeadlessBodyRule,   type:Simple,       presenter:null},
            'oneLivingPlayer'   => {def:OneLivingPlayerRule,    type:Simple,       presenter:null},
            'replenish'         => {def:ReplenishRule,          type:Simple,       presenter:null},
            'resetFreshness'    => {def:ResetFreshnessRule,     type:Simple,       presenter:null},
            'stalemate'         => {def:StalemateRule,          type:Simple,       presenter:null, 
                condition:function(p) return p.maxSkips > 0,
            },
        ];
    }

    override public function defaultParams():Null<MetaParams> {
        return {
            maxSkips: 3,
            playerProperties: new Map(),
            nodeProperties: new Map(),
            globalProperties: new Map(),
        };
    }
}
