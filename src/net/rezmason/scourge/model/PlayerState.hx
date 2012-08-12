package net.rezmason.scourge.model;

class PlayerState {
    public var genome:String;
    public var aspects:Hash<RuleAspect>;
    public var head:GridNode<Cell>;

    public function new():Void {
        aspects = new Hash<RuleAspect>();
    }
}
