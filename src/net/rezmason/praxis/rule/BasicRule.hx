package net.rezmason.praxis.rule;

import net.rezmason.praxis.PraxisTypes;
import net.rezmason.praxis.state.State;

class BasicRule<Params> extends Reckoner {

    var historyState:State;
    var history:StateHistory;
    var params:Params;

    public var moves(default, null):Array<Move> = [{id:0}];
    public var quantumMoves(default, null):Array<Move> = [];
    public var primed(default, null):Bool;
    
    private function _prime():Void {}
    private function _init():Void {}
    private function _update():Void {}
    private function _chooseMove(choice:Int):Void {}
    private function _collectMoves():Void {}
    private function _chooseQuantumMove(choice:Int):Void {}

    var random:Void->Float;
    var changeSignal:Rule->Void;

    @:final public function init(params:Params):Void {
        this.params = params;
        _init();
        primed = false;
    }

    @:final public function prime(state, plan, history, historyState, random:Void->Float, changeSignal:Rule->Void = null):Void {
        this.history = history;
        this.historyState = historyState;
        this.changeSignal = changeSignal;
        this.random = random;
        primePointers(state, plan);
        primed = true;

        #if ROPES_VERBOSE trace('${myName()} initializing'); #end
        _prime();
    }

    @:final public function update():Void {
        #if ROPES_VERBOSE trace('${myName()} updating'); #end
        _update();
    }

    @:final public function chooseMove(choice:Int = -1):Void {
        var defaultChoice:Bool = choice == -1;
        if (defaultChoice) choice = 0;

        if (moves == null || moves.length < choice || moves[choice] == null) {
            throw 'Invalid choice index.';
        }
        #if ROPES_VERBOSE
            if (defaultChoice) trace('${myName()} choosing default move');
            else trace('${myName()} choosing move $choice');
        #end
        _chooseMove(choice);
    }

    @:final public function collectMoves():Void {
        _collectMoves();
    }

    @:final public function chooseQuantumMove(choice:Int):Void {
        if (quantumMoves == null || quantumMoves.length < choice || quantumMoves[choice] == null) {
            throw 'Invalid choice index.';
        }
        #if ROPES_VERBOSE trace('${myName()}choosing quantum move $choice'); #end
        _chooseQuantumMove(choice);
    }

    @:final inline function signalChange() if (changeSignal != null) changeSignal(this);

    @:final public inline function myName():String {
        var name:String = Type.getClassName(Type.getClass(this));
        name = name.substr(name.lastIndexOf('.') + 1);
        return name;
    }

    @:final inline function addGlobal():AspectSet {
        return addAspectSet(plan.globalAspectTemplate, state.globals, historyState.globals, 0);
    }

    @:final inline function addPlayer():AspectSet {
        return addAspectSet(plan.playerAspectTemplate, state.players, historyState.players, numPlayers());
    }

    @:final inline function addNode():AspectSet {
        var node = addAspectSet(plan.nodeAspectTemplate, state.nodes, historyState.nodes, numNodes());
        var locus:BoardLocus = new BoardLocus(node[ident_], node);
        state.loci.push(locus);
        return node;
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
