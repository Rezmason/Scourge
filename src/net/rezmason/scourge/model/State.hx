package net.rezmason.scourge.model;

import net.rezmason.scourge.model.ModelTypes;

class State {

    public var history:StateHistory;

    public var aspects:Aspects;
    public var players:Array<Aspects>;
    public var nodes:Array<BoardNode>;

    public var stateAspectTemplate:AspectTemplate;
    public var playerAspectTemplate:AspectTemplate;
    public var nodeAspectTemplate:AspectTemplate;

    public var stateAspectLookup:AspectLookup;
    public var playerAspectLookup:AspectLookup;
    public var nodeAspectLookup:AspectLookup;

    public function new():Void { }
}
