package net.rezmason.praxis.rule;

import net.rezmason.praxis.PraxisTypes;
import net.rezmason.praxis.state.State;

class Actor<Params> extends Reckoner {

    var historyState:State;
    var history:StateHistory;
    var params:Params;

    public var primed(default, null):Bool;
    
    private function _prime():Void {}
    private function _init():Void {}
    private function _chooseMove(move:Move):Void {}

    var signalChange:Void->Void;

    public function init(params:Params):Void {
        this.params = params;
        _init();
        primed = false;
    }

    @:final public function prime(state, plan, history, historyState, signalChange:Void->Void = null):Void {
        this.history = history;
        this.historyState = historyState;
        if (signalChange == null) signalChange = function() {};
        this.signalChange = signalChange;
        primePointers(state, plan);
        primed = true;
        _prime();
    }

    @:final public function chooseMove(move:Move):Void {
        _chooseMove(move);
    }
}
