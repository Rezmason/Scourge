package net.rezmason.scourge.game.meta;

import net.rezmason.praxis.config.Module;
import net.rezmason.praxis.config.RuleComposition;

class MetaModule extends Module<MetaParams> {

    override public function composeRules():Map<String, RuleComposition<MetaParams>> {
        return [
            'endTurn'           => {type:Simple(new EndTurnActor(), null)},
            'forfeit'           => {type:Action(null, null, new ForfeitActor(), null, null, null)},
            'killHeadlessBody'  => {type:Simple(new KillHeadlessBodyActor(), null)},
            'oneLivingPlayer'   => {type:Simple(new OneLivingPlayerActor(), null)},
            'buildReplenish'    => {type:Builder(new ReplenishBuilder())},
            'replenish'         => {type:Simple(new ReplenishActor(), null)},
            'resetFreshness'    => {type:Simple(new ResetFreshnessActor(), null)},
            'stalemate'         => {type:Simple(new StalemateActor(), null), 
                isIncluded:function(p) return p.maxSkips > 0,
            },
        ];
    }

    override public function makeDefaultParams() {
        return {
            maxSkips: 3,
            playerProperties: new Map(),
            spaceProperties: new Map(),
            cardProperties: new Map(),
            globalProperties: new Map(),
        };
    }
}
