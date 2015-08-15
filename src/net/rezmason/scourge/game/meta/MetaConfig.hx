package net.rezmason.scourge.game.meta;

import net.rezmason.scourge.game.ConfigTypes;

class MetaConfig extends ScourgeConfig<MetaParams> {

    override function get_composition():Map<String, ScourgeRuleComposition<MetaParams>> {
        return [
            'endTurn'           => {def:EndTurnRule,            type:Simple,       presenter:null},
            'forfeit'           => {def:ForfeitRule,            type:Action(null), presenter:null},
            'killHeadlessBody'  => {def:KillHeadlessBodyRule,   type:Simple,       presenter:null},
            'oneLivingPlayer'   => {def:OneLivingPlayerRule,    type:Simple,       presenter:null},
            'replenish'         => {def:ReplenishRule,          type:Simple,       presenter:null},
            'resetFreshness'    => {def:ResetFreshnessRule,     type:Simple,       presenter:null},
            'stalemate'         => {def:StalemateRule,          type:Simple,       presenter:null, 
                isIncluded:function(p) return p.maxSkips > 0,
            },
        ];
    }

    override function get_defaultParams() {
        return {
            maxSkips: 3,
            playerProperties: new Map(),
            spaceProperties: new Map(),
            globalProperties: new Map(),
        };
    }
}
