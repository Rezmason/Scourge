package net.rezmason.scourge.model;

class Evaluator {

    private var historyArray:Array<Int>;

    public function new(historyArray:Array<Int>) { this.historyArray = historyArray; }
    public function evaluate(playerIndex:Int, state:State):Int { return 0; }
}
