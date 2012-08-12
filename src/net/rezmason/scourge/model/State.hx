package net.rezmason.scourge.model;

class State {
    public var players:Array<PlayerState>;
    public var aspects:Hash<RuleAspect>;
    public var currentPlayer:Int;

    public function new():Void {
        players = [];
        currentPlayer = 0;
        aspects = new Hash<RuleAspect>();
    }
}
