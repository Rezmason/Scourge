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
        writeAspectSets(state.players, historyState.players);
        writeAspectSets(state.nodes, historyState.nodes);
        writeAspectSets(state.extras, historyState.extras);
    }

    public function read():Void {
        readAspects(state.aspects, historyState.aspects, aItr);
        readAspectSets(state.players, historyState.players);
        readAspectSets(state.nodes, historyState.nodes);
        readAspectSets(state.extras, historyState.extras);
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
        for (ptr in aspects.ptrs(key, aItr)) history.write(histAspects[ptr], aspects[ptr]);
    }

    private inline function writeAspectSets(aspectSets:Array<AspectSet>, histAspectSets:Array<AspectSet>):Void {
        for (ike in 0...aspectSets.length) writeAspects(aspectSets[ike], histAspectSets[ike], aItr);
    }

    private inline function readAspects(aspects:AspectSet, histAspects:AspectSet, itr:AspectItr):Void {
        for (ptr in aspects.ptrs(key, aItr)) aspects[ptr] = history.read(histAspects[ptr]);
    }

    private inline function readAspectSets(aspectSets:Array<AspectSet>, histAspectSets:Array<AspectSet>):Void {
        for (ike in 0...aspectSets.length) readAspects(aspectSets[ike], histAspectSets[ike], aItr);
    }
}

