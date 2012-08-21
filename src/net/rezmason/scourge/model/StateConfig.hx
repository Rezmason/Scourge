package net.rezmason.scourge.model;

import net.rezmason.scourge.model.ModelTypes;

class StateConfig {

    public var numPlayers:Int;
    public var playerHeads:Array<Int>;
    public var nodes:Array<BoardNode>;
    public var rules:Array<Rule>;

    public function new():Void { }
}
