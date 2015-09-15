package net.rezmason.praxis.rule;

import net.rezmason.praxis.PraxisTypes;
import net.rezmason.praxis.Reckoner;
import net.rezmason.praxis.state.State;
import net.rezmason.praxis.state.StatePlan;
import net.rezmason.utils.Zig;

interface IRule {
    public var isRandom(default, null):Bool;
    public var moves(default, null):Array<Move>;
    public var primed(default, null):Bool;
    public var reckoners(default, null):Array<Reckoner>;

    public function prime(state:State, plan:StatePlan, history:StateHistory, historyState:State, changeSignal:String->Void = null):Void;
    public function update():Void;
    public function chooseMove(index:Int = -1):Void;
    public function collectMoves():Void;
    public function cacheMoves(cacheMovesSignal:Zig<Int->Void>, revGetter:Void->Int):Void;
}

