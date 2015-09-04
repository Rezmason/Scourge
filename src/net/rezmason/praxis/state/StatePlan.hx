package net.rezmason.praxis.state;

import net.rezmason.praxis.PraxisTypes;

@:allow(net.rezmason.praxis.state.StatePlanner)
class StatePlan {

    var globalAspectTemplate(default, null):AspectSet = new AspectSet();
    var playerAspectTemplate(default, null):AspectSet = new AspectSet();
    var cardAspectTemplate(default, null):AspectSet = new AspectSet();
    var spaceAspectTemplate(default, null):AspectSet = new AspectSet();

    var globalAspectLookup(default, null):AspectLookup = new AspectLookup();
    var playerAspectLookup(default, null):AspectLookup = new AspectLookup();
    var cardAspectLookup(default, null):AspectLookup = new AspectLookup();
    var spaceAspectLookup(default, null):AspectLookup = new AspectLookup();

    public function new():Void {}

    public inline function onGlobal(prop:AspectProperty) return globalAspectLookup[prop.id];
    public inline function onPlayer(prop:AspectProperty) return playerAspectLookup[prop.id];
    public inline function onCard(prop:AspectProperty) return cardAspectLookup[prop.id];
    public inline function onSpace(prop:AspectProperty) return spaceAspectLookup[prop.id];

    public inline function globalDefaults():AspectSet return globalAspectTemplate.copy();
    public inline function playerDefaults():AspectSet return playerAspectTemplate.copy();
    public inline function cardDefaults():AspectSet return cardAspectTemplate.copy();
    public inline function spaceDefaults():AspectSet return spaceAspectTemplate.copy();
}
