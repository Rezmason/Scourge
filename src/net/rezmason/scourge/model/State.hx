package net.rezmason.scourge.model;

import net.rezmason.scourge.model.ModelTypes;

class State {

    public var aspects:AspectSet;
    public var players:Array<AspectSet>;
    public var nodes:Array<BoardNode>;

    public var stateAspectTemplate:AspectSet;
    public var playerAspectTemplate:AspectSet;
    public var nodeAspectTemplate:AspectSet;

    public var stateAspectLookup:AspectLookup;
    public var playerAspectLookup:AspectLookup;
    public var nodeAspectLookup:AspectLookup;

    public function new():Void { }
}
