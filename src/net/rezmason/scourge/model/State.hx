package net.rezmason.scourge.model;

import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.aspects.Aspect;

class State {
    public var players:Array<PlayerState>;
    public var aspects:Aspects;
    public var currentPlayer:Int;

    public function new():Void {
        players = [];
        currentPlayer = 0;
        aspects = new Aspects();
    }
}
