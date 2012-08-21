package net.rezmason.scourge.model;

class Evaluator {

    private var history:History<Int>;
    private var state:State;

    public function new(state:State) {
        this.state = state;
        history = state.history;
    }
    public function evaluate():Int { return 0; }
}
