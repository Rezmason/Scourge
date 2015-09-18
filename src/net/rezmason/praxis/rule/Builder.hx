package net.rezmason.praxis.rule;

import net.rezmason.praxis.PraxisTypes;

class Builder<Params> extends RuleElement<Params> {
    @:final inline function addGlobal():Global return state.addGlobal(plan.globalDefaults(), globalIdent_);
    @:final inline function addPlayer():Player return state.addPlayer(plan.playerDefaults(), playerIdent_);
    @:final inline function addCard():Card return state.addCard(plan.cardDefaults(), cardIdent_);
    @:final inline function addSpace():Space return state.addSpace(plan.spaceDefaults(), spaceIdent_);
    @:final inline function addExtra():Extra return state.addExtra(extraDefaults(), extraIdent_);
}
