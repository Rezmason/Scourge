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
        for (aspects in state.globals) historyState.globals.push(aspects.map(history.alloc));
        for (aspects in state.players) historyState.players.push(aspects.map(history.alloc));
        for (aspects in state.cards)   historyState.cards  .push(aspects.map(history.alloc));
        for (aspects in state.spaces)  historyState.spaces .push(aspects.map(history.alloc));
        for (aspects in state.extras)  historyState.extras .push(aspects.map(history.alloc));
        
        write();
        history.forget();
    }

    public function write():Void {
        writeAspectPointables(state.globals, historyState.globals, aItr);
        writeAspectPointables(state.players, historyState.players, aItr);
        writeAspectPointables(state.spaces, historyState.spaces, aItr);
        writeAspectPointables(state.extras, historyState.extras, aItr);
    }

    public function read():Void {
        readAspectPointables(state.globals, historyState.globals, aItr);
        readAspectPointables(state.players, historyState.players, aItr);
        readAspectPointables(state.spaces, historyState.spaces, aItr);
        readAspectPointables(state.extras, historyState.extras, aItr);
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

