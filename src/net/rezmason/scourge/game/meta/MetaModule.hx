package net.rezmason.scourge.game.meta;

import net.rezmason.praxis.config.Module;
import net.rezmason.praxis.config.RuleComposition;

class MetaModule extends Module<MetaParams> {

    override function get_composition():Map<String, RuleComposition<MetaParams>> {
        return [
            'endTurn'           => {type:Simple(new EndTurnRule(), null)},
            'forfeit'           => {type:Action(new ForfeitRule(), null, null, null)},
            'killHeadlessBody'  => {type:Simple(new KillHeadlessBodyRule(), null)},
            'oneLivingPlayer'   => {type:Simple(new OneLivingPlayerRule(), null)},
            'replenish'         => {type:Simple(new ReplenishRule(), null)},
            'resetFreshness'    => {type:Simple(new ResetFreshnessRule(), null)},
            'stalemate'         => {type:Simple(new StalemateRule(), null), 
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
