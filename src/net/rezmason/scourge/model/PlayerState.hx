package net.rezmason.scourge.model;

import net.rezmason.scourge.model.aspects.Aspect;

class PlayerState {
    public var genome:String;
    public var aspects:IntHash<Aspect>;
    public var head:GridNode<IntHash<Aspect>>;

    public function new():Void {
        aspects = new IntHash<Aspect>();
    }
}
