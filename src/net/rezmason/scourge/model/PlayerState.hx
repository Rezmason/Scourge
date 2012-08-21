package net.rezmason.scourge.model;

import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.Aspect;

class PlayerState {
    public var aspects:Aspects;
    public var head:Int;

    public function new():Void {
        aspects = new Aspects();
    }
}
