package net.rezmason.scourge.model;

class State {
    public var players:Array<PlayerState>;
    public var aspects:IntHash<RuleAspect>;
    public var currentPlayer:Int;

    public function new():Void {
        players = [];
        currentPlayer = 0;
        aspects = new IntHash<RuleAspect>();
    }
}
