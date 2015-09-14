package net.rezmason.praxis.rule;

import net.rezmason.praxis.PraxisTypes;
import net.rezmason.praxis.state.State;

class BaseRule<Params> extends Reckoner {

    var historyState:State;
    var history:StateHistory;
    var params:Params;

    public var isRandom(default, null):Bool;
    public var moves(default, null):Array<Move> = [{id:0}];
    public var primed(default, null):Bool;
    
    private function _prime():Void {}
    private function _init():Void {}
    private function _update():Void {}
    private function _chooseMove(choice:Int):Void {}
    private function _collectMoves():Void {}

    @:allow(net.rezmason.praxis.config.GameConfig) var id:String;
    var changeSignal:String->Void;

    public function init(params:Params, isRandom:Bool = false):Void {
        this.params = params;
        this.isRandom = isRandom;
        _init();
        primed = false;
    }

    @:final public function prime(state, plan, history, historyState, changeSignal:String->Void = null):Void {
        this.history = history;
        this.historyState = historyState;
        this.changeSignal = changeSignal;
        primePointers(state, plan);
        primed = true;
        _prime();
    }

    @:final public function update():Void _update();

    @:final public function chooseMove(choice:Int = -1):Void {
        var defaultChoice:Bool = choice == -1;
        if (defaultChoice) choice = 0;

        if (moves == null || moves.length < choice || moves[choice] == null) {
            throw 'Invalid choice index.';
        }
        _chooseMove(choice);
    }

    @:final public function collectMoves():Void {
        _collectMoves();
    }

    @:final inline function signalChange() if (changeSignal != null) changeSignal(id);

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
