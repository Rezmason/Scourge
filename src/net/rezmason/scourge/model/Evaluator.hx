package net.rezmason.scourge.model;

class Evaluator {

    private var historyArray:Array<Int>;
    private var state:State;

    public function new(state:State) {
        this.state = state;
        historyArray = state.historyArray;
    }
    public function evaluate():Int { return 0; }
}
