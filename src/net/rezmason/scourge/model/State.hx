package net.rezmason.scourge.model;

import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.Aspect;

class State {
    public var players:Array<PlayerState>;
    public var nodes:Array<BoardNode>;
    public var aspects:Aspects;
    public var historyArray:Array<Int>;

    public function new(historyArray:Array<Int>):Void {
        players = [];
        aspects = new Aspects();
        this.historyArray = historyArray;
    }
}
