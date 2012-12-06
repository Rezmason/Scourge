package net.rezmason.ropes;

import net.rezmason.ropes.Types;

class StateHistorian {

    public var state(default, null):State;
    public var historyState(default, null):State;
    public var history(default, null):StateHistory;

    public function new():Void {
        state = new State();
        historyState = new State();
        history = new StateHistory();
    }

    public function write():Void {
        writeAspects(state.aspects, historyState.aspects);
        for (ike in 0...state.players.length) writeAspects(state.players[ike], historyState.players[ike]);
        for (ike in 0...state.nodes.length) writeAspects(state.nodes[ike].value, historyState.nodes[ike].value);
        for (ike in 0...state.extras.length) writeAspects(state.extras[ike], historyState.extras[ike]);
    }

    public function read():Void {
        readAspects(state.aspects, historyState.aspects);
        for (ike in 0...state.players.length) readAspects(state.players[ike], historyState.players[ike]);
        for (ike in 0...state.nodes.length) readAspects(state.nodes[ike].value, historyState.nodes[ike].value);
        for (ike in 0...state.extras.length) readAspects(state.extras[ike], historyState.extras[ike]);
    }

    public function reset():Void {
        state.wipe();
        historyState.wipe();
        history.wipe();
    }

    private inline function writeAspects(aspects:AspectSet, histAspects:AspectSet):Void {
        for (ike in 0...aspects.length) history.set(histAspects[ike], aspects[ike]);
    }

    private inline function readAspects(aspects:AspectSet, histAspects:AspectSet):Void {
        for (ike in 0...aspects.length) aspects[ike] = history.get(histAspects[ike]);
    }
}

