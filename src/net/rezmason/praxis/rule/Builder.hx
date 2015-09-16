package net.rezmason.praxis.rule;

import net.rezmason.praxis.PraxisTypes;
import net.rezmason.praxis.state.State;

class Builder<Params> extends Reckoner {

    var historyState:State;
    var history:StateHistory;
    var params:Params;

    public var primed(default, null):Bool;
    
    private function _prime():Void {}
    private function _init():Void {}

    public function init(params:Params):Void {
        this.params = params;
        _init();
        primed = false;
    }

    @:final public function prime(state, plan, history, historyState):Void {
        this.history = history;
        this.historyState = historyState;
        primePointers(state, plan);
        primed = true;
        _prime();
    }

    @:final inline function addGlobal():Global {
        return addAspectPointable(plan.globalDefaults(), globalIdent_, state.globals, historyState.globals, 0);
    }

    @:final inline function addPlayer():Player {
        return addAspectPointable(plan.playerDefaults(), playerIdent_, state.players, historyState.players, numPlayers());
    }

    @:final inline function addCard():Card {
        return addAspectPointable(plan.cardDefaults(), cardIdent_, state.cards, historyState.cards, numCards());
    }

    @:final inline function addSpace():Space {
        var space = addAspectPointable(plan.spaceDefaults(), spaceIdent_, state.spaces, historyState.spaces, numSpaces());
        state.cells.addCell(space);
        return space;
    }

    @:final inline function addExtra():Extra {
        return addAspectPointable(extraDefaults(), extraIdent_, state.extras, historyState.extras, numExtras());
    }

    @:final inline function addAspectPointable<T>(template:AspectPointable<T>, ident, list, histList, id):AspectPointable<T> {
        template[ident] = id;
        list.push(template);
        template[ident] = id;
        histList.push(template.map(history.alloc));
        state.resolve();
        return template;
    }
}
