package net.rezmason.scourge.model;

import net.rezmason.scourge.model.ModelTypes;

class StatePlan {

    public var stateAspectTemplate(default, null):AspectSet;
    public var playerAspectTemplate(default, null):AspectSet;
    public var nodeAspectTemplate(default, null):AspectSet;

    public var stateAspectLookup(default, null):AspectLookup;
    public var playerAspectLookup(default, null):AspectLookup;
    public var nodeAspectLookup(default, null):AspectLookup;

    public function new():Void {
        stateAspectTemplate = [];
        playerAspectTemplate = [];
        nodeAspectTemplate = [];

        stateAspectLookup = [];
        playerAspectLookup = [];
        nodeAspectLookup = [];
    }
}
