package net.rezmason.praxis.state;

import haxe.Unserializer;
import net.rezmason.praxis.PraxisTypes;
import net.rezmason.utils.SafeSerializer;
import net.rezmason.utils.pointers.Pointers;

class StateHistorian {

    public var state(default, null):State;
    public var historyState(default, null):State;
    public var history(default, null):StateHistory;

    var aItr:AspectItr;

    public function new():Void {
        state = new State();
        historyState = new State();
        history = new StateHistory();
        aItr = new AspectItr();
    }

    public function write():Void {
        writeAspectSets(state.globals, historyState.globals);
        writeAspectSets(state.players, historyState.players);
        writeAspectSets(state.spaces, historyState.spaces);
        writeAspectSets(state.extras, historyState.extras);
    }

    public function read():Void {
        readAspectSets(state.globals, historyState.globals);
        readAspectSets(state.players, historyState.players);
        readAspectSets(state.spaces, historyState.spaces);
        readAspectSets(state.extras, historyState.extras);
    }

    public function save():SavedState {
        return {data:SafeSerializer.run(state)};
    }

    public function load(savedState:SavedState) {
        var oldState = state;
        state = Unserializer.run(savedState.data);
        if (oldState != null) state.cells = oldState.cells.copy();
    }

    public function reset():Void {
        state.wipe();
        historyState.wipe();
        history.wipe();
    }

    private inline function writeAspects(aspects:AspectSet, histAspects:AspectSet, aItr:AspectItr):Void {
        for (ptr in aspects.ptrs(aItr)) history.write(histAspects[ptr], aspects[ptr]);
    }

    private inline function writeAspectSets(aspectSets:Array<AspectSet>, histAspectSets:Array<AspectSet>):Void {
        for (ike in 0...aspectSets.length) writeAspects(aspectSets[ike], histAspectSets[ike], aItr);
    }

    private inline function readAspects(aspects:AspectSet, histAspects:AspectSet, itr:AspectItr):Void {
        for (ptr in aspects.ptrs(aItr)) aspects[ptr] = history.read(histAspects[ptr]);
    }

    private inline function readAspectSets(aspectSets:Array<AspectSet>, histAspectSets:Array<AspectSet>):Void {
        for (ike in 0...aspectSets.length) readAspects(aspectSets[ike], histAspectSets[ike], aItr);
    }
}

