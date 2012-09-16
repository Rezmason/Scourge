package net.rezmason.scourge.model;

import net.rezmason.scourge.model.ModelTypes;

class StateHistorian {

    public var state(default, null):State;
    public var historyState(default, null):State;
    public var history(default, null):StateHistory;

    var a:Array<Int>;

    public function new():Void {
        a = [];
        state = new State();
        historyState = new State();
        history = new StateHistory();
    }

    public function write():Void {
        writeAspects(state.aspects, historyState.aspects);
        for (ike in 0...state.players.length)
            writeAspects(state.players[ike], historyState.players[ike]);
        for (ike in 0...state.nodes.length)
            writeAspects(state.nodes[ike].value, historyState.nodes[ike].value);
        //trace(a.join(""));
    }

    public function read():Void {
        readAspects(state.aspects, historyState.aspects);
        for (ike in 0...state.players.length)
            readAspects(state.players[ike], historyState.players[ike]);
        for (ike in 0...state.nodes.length)
            readAspects(state.nodes[ike].value, historyState.nodes[ike].value);
        //trace(a.join(""));
    }

    private inline function writeAspects(aspects:AspectSet, histAspects:AspectSet):Void {
        for (ike in 0...aspects.length) {
            history.set(histAspects[ike], aspects[ike]);
            if (a[histAspects[ike]] == null) a[histAspects[ike]] = 1;
            else a[histAspects[ike]]++;
        }
    }

    private inline function readAspects(aspects:AspectSet, histAspects:AspectSet):Void {
        for (ike in 0...aspects.length) {
            aspects[ike] = history.get(histAspects[ike]);
            a[histAspects[ike]]--;
        }
    }
}

