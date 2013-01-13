package net.rezmason.ropes;

import haxe.Unserializer;
import net.rezmason.ropes.Types;
import net.rezmason.utils.SafeSerializer;
import net.rezmason.utils.Pointers;

class StateHistorian {

    public var state(default, null):State;
    public var historyState(default, null):State;
    public var history(default, null):StateHistory;
    public var key(default, null):PtrSet;

    public function new():Void {
        key = Pointers.makeSet();
        state = new State(key);
        historyState = new State(key);
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

    public function save():SavedState {
        return {data:SafeSerializer.run(state)};
    }

    public function load(savedState:SavedState) {
        state = Unserializer.run(savedState.data);
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

