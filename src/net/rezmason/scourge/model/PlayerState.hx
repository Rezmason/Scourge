package net.rezmason.scourge.model;

class PlayerState {
    public var genome:String;
    public var aspects:IntHash<RuleAspect>;
    public var head:GridNode<IntHash<RuleAspect>>;

    public function new():Void {
        aspects = new IntHash<RuleAspect>();
    }
}
