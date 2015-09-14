package net.rezmason.scourge.game.meta;

import net.rezmason.scourge.game.ConfigTypes;

class MetaConfig extends ScourgeConfig<MetaParams> {

    override function get_composition():Map<String, ScourgeRuleComposition<MetaParams>> {
        return [
            'endTurn'           => {def:new EndTurnRule(),            type:Simple,       presenter:null},
            'forfeit'           => {def:new ForfeitRule(),            type:Action(null), presenter:null},
            'killHeadlessBody'  => {def:new KillHeadlessBodyRule(),   type:Simple,       presenter:null},
            'oneLivingPlayer'   => {def:new OneLivingPlayerRule(),    type:Simple,       presenter:null},
            'replenish'         => {def:new ReplenishRule(),          type:Simple,       presenter:null},
            'resetFreshness'    => {def:new ResetFreshnessRule(),     type:Simple,       presenter:null},
            'stalemate'         => {def:new StalemateRule(),          type:Simple,       presenter:null, 
                isIncluded:function(p) return p.maxSkips > 0,
            },
        ];
    }

    override function get_defaultParams() {
        return {
            maxSkips: 3,
            playerProperties: new Map(),
            spaceProperties: new Map(),
            cardProperties: new Map(),
            globalProperties: new Map(),
        };
    }
}
