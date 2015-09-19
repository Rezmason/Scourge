package net.rezmason.praxis.state;

import haxe.Unserializer;
import net.rezmason.praxis.PraxisTypes;
import net.rezmason.utils.SafeSerializer;

class StateHistorian {

    public var state(default, null):State;
    public var historyState(default, null):State;
    public var history(default, null):StateHistory;

    var aItr:AspectIterator<Dynamic>;

    public function new():Void {
        state = new State();
        historyState = new State();
        history = new StateHistory();
        aItr = new AspectIterator();
    }

    public function init() {
        for (aspects in state._globals) historyState._globals.push(aspects.map(history.alloc));
        for (aspects in state._players) historyState._players.push(aspects.map(history.alloc));
        for (aspects in state._cards)   historyState._cards  .push(aspects.map(history.alloc));
        for (aspects in state._spaces)  historyState._spaces .push(aspects.map(history.alloc));
        for (aspects in state._extras)  historyState._extras .push(aspects.map(history.alloc));
        
        write();
        history.forget();
    }

    public function write():Void {
        writeAspectPointables(state._globals, historyState._globals, aItr);
        writeAspectPointables(state._players, historyState._players, aItr);
        writeAspectPointables(state._spaces, historyState._spaces, aItr);
        writeAspectPointables(state._extras, historyState._extras, aItr);
    }

    public function read():Void {
        readAspectPointables(state._globals, historyState._globals, aItr);
        readAspectPointables(state._players, historyState._players, aItr);
        readAspectPointables(state._spaces, historyState._spaces, aItr);
        readAspectPointables(state._extras, historyState._extras, aItr);
    }

    public function save():SavedState {
        return {data:SafeSerializer.run(state)};
    }

    public function load(savedState:SavedState) {
        var oldState = state;
        state = Unserializer.run(savedState.data);
        if (oldState != null) state.cells.copyFrom(oldState.cells);
    }

    public function reset():Void {
        state.wipe();
        historyState.wipe();
        history.wipe();
    }

    private inline function writeAspects<T>(aspects:AspectPointable<T>, histAspects:AspectPointable<T>, aItr:AspectIterator<Dynamic>):Void {
        for (ptr in aspects.ptrs(cast aItr)) history.write(histAspects[ptr], aspects[ptr]);
    }

    private inline function writeAspectPointables<T>(aspectPointables:Array<AspectPointable<T>>, histAspectPointables:Array<AspectPointable<T>>, aItr:AspectIterator<Dynamic>):Void {
        for (ike in 0...aspectPointables.length) writeAspects(aspectPointables[ike], histAspectPointables[ike], aItr);
    }

    private inline function readAspects<T>(aspects:AspectPointable<T>, histAspects:AspectPointable<T>, aItr:AspectIterator<Dynamic>):Void {
        for (ptr in aspects.ptrs(cast aItr)) aspects[cast ptr] = history.read(histAspects[cast ptr]);
    }

    private inline function readAspectPointables<T>(aspectPointables:Array<AspectPointable<T>>, histAspectPointables:Array<AspectPointable<T>>, aItr:AspectIterator<Dynamic>):Void {
        for (ike in 0...aspectPointables.length) readAspects(aspectPointables[ike], histAspectPointables[ike], aItr);
    }
}

