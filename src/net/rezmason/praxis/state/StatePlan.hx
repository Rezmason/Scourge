package net.rezmason.praxis.state;

import net.rezmason.praxis.PraxisTypes;

class StatePlan {

    public var globalAspectTemplate(default, null):AspectSet = new AspectSet();
    public var playerAspectTemplate(default, null):AspectSet = new AspectSet();
    public var cardAspectTemplate(default, null):AspectSet = new AspectSet();
    public var spaceAspectTemplate(default, null):AspectSet = new AspectSet();

    public var globalAspectLookup(default, null):AspectLookup = new AspectLookup();
    public var playerAspectLookup(default, null):AspectLookup = new AspectLookup();
    public var cardAspectLookup(default, null):AspectLookup = new AspectLookup();
    public var spaceAspectLookup(default, null):AspectLookup = new AspectLookup();

    public function new():Void {}

    public inline function onGlobal(prop:AspectProperty) return globalAspectLookup[prop.id];
    public inline function onPlayer(prop:AspectProperty) return playerAspectLookup[prop.id];
    public inline function onCard(prop:AspectProperty) return cardAspectLookup[prop.id];
    public inline function onSpace(prop:AspectProperty) return spaceAspectLookup[prop.id];
}
