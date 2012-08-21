package net.rezmason.scourge.model;

import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.Aspect;

class State {
    public var players:Array<PlayerState>;
    public var nodes:Array<BoardNode>;
    public var aspects:Aspects;
    public var history:History<Int>;

    public function new(history:History<Int>):Void {
        players = [];
        aspects = new Aspects();
        this.history = history;
    }
}
