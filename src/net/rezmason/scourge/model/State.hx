package net.rezmason.scourge.model;

import net.rezmason.scourge.model.aspects.Aspect;

class State {
    public var players:Array<PlayerState>;
    public var aspects:IntHash<Aspect>;
    public var currentPlayer:Int;

    public function new():Void {
        players = [];
        currentPlayer = 0;
        aspects = new IntHash<Aspect>();
    }
}
