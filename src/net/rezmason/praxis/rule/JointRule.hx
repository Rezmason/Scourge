package net.rezmason.praxis.rule;

import net.rezmason.praxis.PraxisTypes;

using net.rezmason.utils.MapUtils;

class JointRule implements IRule {
    public var isRandom(default, null):Bool;
    public var moves(default, null):Array<Move> = [{id:0}];
    public var primed(default, null):Bool;
    public var reckoners:Array<Reckoner>;

    var sequence:Array<IRule>;

    public function new(sequence:Array<IRule>) {
        this.sequence = sequence;
        reckoners = [for (rule in sequence) for (reckoner in rule.reckoners) reckoner];
        primed = false;
    }

    public function prime(state, plan, history, historyState, changeSignal = null):Void {
        for (rule in sequence) if (!rule.primed) rule.prime(state, plan, history, historyState, changeSignal);
        primed = true;
    }

    public function update():Void {
        sequence[0].update();
        moves = sequence[0].moves;
    }

    public function chooseMove(index:Int = -1):Void {
        sequence[0].chooseMove(index);
        for (ike in 1...sequence.length) sequence[ike].chooseMove();
    }

    public function collectMoves():Void {
        sequence[0].collectMoves();
        moves = null;
    }

    public function cacheMoves(_, _) {}
}

