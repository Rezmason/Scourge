package net.rezmason.scourge.game.meta;

import net.rezmason.praxis.config.Module;
import net.rezmason.praxis.config.RuleComposition;
import net.rezmason.praxis.config.RuleType;

class MetaModule extends Module<MetaParams> {

    override public function composeRules():Map<String, RuleComposition<MetaParams>> {
        var rules:Map<String, RuleComposition<MetaParams>> = new Map();
        rules[           'endTurn'] = {type:Simple(new EndTurnActor(), null), isIncluded: null};
        rules[           'forfeit'] = {type:Action(null, null, new ForfeitActor(), null, null, null), isIncluded: null};
        rules[  'killHeadlessBody'] = {type:Simple(new KillHeadlessBodyActor(), null), isIncluded: null};
        rules[   'oneLivingPlayer'] = {type:Simple(new OneLivingPlayerActor(), null), isIncluded: null};
        rules[    'buildReplenish'] = {type:Builder(new ReplenishBuilder()), isIncluded: null};
        rules[         'replenish'] = {type:Simple(new ReplenishActor(), null), isIncluded: null};
        rules[    'resetFreshness'] = {type:Simple(new ResetFreshnessActor(), null), isIncluded: null};
        rules[         'stalemate'] = {
            type:Simple(new StalemateActor(), null),
            isIncluded:function(p:MetaParams) return p.maxSkips > 0,
        };
        return rules;
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
