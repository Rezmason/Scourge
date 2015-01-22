package net.rezmason.ropes;

import net.rezmason.ropes.RopesTypes;

class StatePlan {

    public var globalAspectTemplate(default, null):AspectSet = new AspectSet();
    public var playerAspectTemplate(default, null):AspectSet = new AspectSet();
    public var nodeAspectTemplate(default, null):AspectSet = new AspectSet();

    public var globalAspectLookup(default, null):AspectLookup = new AspectLookup();
    public var playerAspectLookup(default, null):AspectLookup = new AspectLookup();
    public var nodeAspectLookup(default, null):AspectLookup = new AspectLookup();

    public function new():Void {}

    public inline function onGlobal(prop:AspectProperty) return globalAspectLookup[prop.id];
    public inline function onPlayer(prop:AspectProperty) return playerAspectLookup[prop.id];
    public inline function onNode(prop:AspectProperty) return nodeAspectLookup[prop.id];
}
