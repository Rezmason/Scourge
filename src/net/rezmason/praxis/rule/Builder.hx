package net.rezmason.praxis.rule;

import net.rezmason.praxis.PraxisTypes;

class Builder<Params> extends RuleElement<Params> {
    
    @:final inline function addGlobal():Global {
        return addAspectPointable(plan.globalDefaults(), globalIdent_, state.globals, 0);
    }

    @:final inline function addPlayer():Player {
        return addAspectPointable(plan.playerDefaults(), playerIdent_, state.players, numPlayers());
    }

    @:final inline function addCard():Card {
        return addAspectPointable(plan.cardDefaults(), cardIdent_, state.cards, numCards());
    }

    @:final inline function addSpace():Space {
        return addAspectPointable(plan.spaceDefaults(), spaceIdent_, state.spaces, numSpaces());
    }

    @:final inline function addExtra():Extra {
        return addAspectPointable(extraDefaults(), extraIdent_, state.extras, numExtras());
    }

    @:final inline function addAspectPointable<T>(template:AspectPointable<T>, ident, list, id):AspectPointable<T> {
        template[ident] = id;
        list.push(template);
        return template;
    }
}
