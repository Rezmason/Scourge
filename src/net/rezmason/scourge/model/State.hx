package net.rezmason.scourge.model;

import haxe.FastList;

class State {
    public var players:Array<PlayerState>;
    public var aspects:Hash<FastList<RuleAspect>>;
    public var currentPlayer:Int;

    public function new():Void {
        players = [];
        currentPlayer = 0;
        aspects = new Hash<FastList<RuleAspect>>();
    }
}
