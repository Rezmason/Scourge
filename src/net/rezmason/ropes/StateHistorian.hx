package net.rezmason.ropes;

import haxe.Unserializer;
import net.rezmason.ropes.RopesTypes;
import net.rezmason.utils.SafeSerializer;
import net.rezmason.utils.Pointers;

class StateHistorian {

    public var state(default, null):State;
    public var historyState(default, null):State;
    public var history(default, null):StateHistory;
    public var key(default, null):PtrKey;

    var aItr:AspectItr;

    public function new():Void {
        key = new PtrKey();
        state = new State(key);
        historyState = new State(key);
        history = new StateHistory();
        aItr = new AspectItr();
    }

    public function write():Void {
        writeAspects(state.aspects, historyState.aspects, aItr);
        for (ike in 0...state.players.length) writeAspects(state.players[ike], historyState.players[ike], aItr);
        for (ike in 0...state.nodes  .length) writeAspects(state.nodes  [ike], historyState.nodes  [ike], aItr);
        for (ike in 0...state.extras .length) writeAspects(state.extras [ike], historyState.extras [ike], aItr);
    }

    public function read():Void {
        readAspects(state.aspects, historyState.aspects, aItr);
        for (ike in 0...state.players.length) readAspects(state.players[ike], historyState.players[ike], aItr);
        for (ike in 0...state.nodes  .length) readAspects(state.nodes  [ike], historyState.nodes  [ike], aItr);
        for (ike in 0...state.extras .length) readAspects(state.extras [ike], historyState.extras [ike], aItr);
    }

    public function save():SavedState {
        return {data:SafeSerializer.run(state)};
    }

    public function load(savedState:SavedState) {
        state = Unserializer.run(savedState.data);
        state.key = key;
    }

    public function reset():Void {
        state.wipe();
        historyState.wipe();
        history.wipe();
    }

    private inline function writeAspects(aspects:AspectSet, histAspects:AspectSet, aItr:AspectItr):Void {
        for (ptr in aspects.ptrs(key, aItr)) history.set(histAspects[ptr], aspects[ptr]);
    }

    private inline function readAspects(aspects:AspectSet, histAspects:AspectSet, itr:AspectItr):Void {
        for (ptr in aspects.ptrs(key, aItr)) aspects[ptr] = history.get(histAspects[ptr]);
    }
}

