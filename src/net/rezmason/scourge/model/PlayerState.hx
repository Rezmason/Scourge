package net.rezmason.scourge.model;

import haxe.FastList;

class PlayerState {
    public var genome:String;
    public var aspects:Hash<FastList<RuleAspect>>;
    public var head:GridNode<Cell>;

    public function new():Void {
        aspects = new Hash<FastList<RuleAspect>>();
    }
}
