package net.rezmason.scourge.model;

import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.aspects.Aspect;

class PlayerState {
    public var genome:String;
    public var aspects:Aspects;
    public var head:BoardNode;

    public function new():Void {
        aspects = new Aspects();
    }
}
