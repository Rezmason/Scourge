package net.rezmason.praxis.rule;

import net.rezmason.praxis.PraxisTypes;
import net.rezmason.praxis.state.State;

class Surveyor<Params> extends Reckoner {

    var historyState:State;
    var history:StateHistory;
    var params:Params;

    public var moves(default, null):Array<Move> = [{id:0}];
    public var primed(default, null):Bool;
    
    private function _prime():Void {}
    private function _init():Void {}
    private function _update():Void {}
    private function _collectMoves():Void {}

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

    @:final public function update():Void _update();

    @:final public function collectMoves():Void {
        _collectMoves();
    }
}
