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

    public function new(params:Params, isRandom:Bool = false):Void {
        super();
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

        #if PRAXIS_VERBOSE trace('${myName()} initializing'); #end
        _prime();
    }

    @:final public function update():Void {
        #if PRAXIS_VERBOSE trace('${myName()} updating'); #end
        _update();
    }

    @:final public function chooseMove(choice:Int = -1):Void {
        var defaultChoice:Bool = choice == -1;
        if (defaultChoice) choice = 0;

        if (moves == null || moves.length < choice || moves[choice] == null) {
            throw 'Invalid choice index.';
        }
        #if PRAXIS_VERBOSE
            if (defaultChoice) trace('${myName()} choosing default move');
            else trace('${myName()} choosing move $choice');
        #end
        _chooseMove(choice);
    }

    @:final public function collectMoves():Void {
        _collectMoves();
    }

    @:final inline function signalChange() if (changeSignal != null) changeSignal(id);

    @:final inline function addGlobal():AspectSet {
        return addAspectSet(plan.globalAspectTemplate, state.globals, historyState.globals, 0);
    }

    @:final inline function addPlayer():AspectSet {
        return addAspectSet(plan.playerAspectTemplate, state.players, historyState.players, numPlayers());
    }

    @:final inline function addCard():AspectSet {
        return addAspectSet(plan.cardAspectTemplate, state.cards, historyState.cards, numCards());
    }

    @:final inline function addSpace():AspectSet {
        var space = addAspectSet(plan.spaceAspectTemplate, state.spaces, historyState.spaces, numSpaces());
        var cell:BoardCell = new BoardCell(getID(space), space);
        state.cells.push(cell);
        return space;
    }

    @:final inline function addExtra():AspectSet {
        return addAspectSet(extraAspectTemplate, state.extras, historyState.extras, numExtras());
    }

    @:final inline function addAspectSet(template:AspectSet, list, histList, id):AspectSet {
        var aspectSet:AspectSet = template.copy();
        aspectSet[ident_] = id;
        list.push(aspectSet);
        template[ident_] = id;
        histList.push(template.map(history.alloc));
        state.resolve();
        return aspectSet;
    }
}
