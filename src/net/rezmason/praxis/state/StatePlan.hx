package net.rezmason.praxis.state;

import net.rezmason.praxis.PraxisTypes;

@:allow(net.rezmason.praxis.state.StatePlanner)
class StatePlan {

    var globalAspectTemplate(default, null):Global = new AspectPointable();
    var playerAspectTemplate(default, null):Player = new AspectPointable();
    var cardAspectTemplate(default, null):Card = new AspectPointable();
    var spaceAspectTemplate(default, null):Space = new AspectPointable();

    var globalAspectLookup(default, null):AspectLookup<PGlobal> = new AspectLookup();
    var playerAspectLookup(default, null):AspectLookup<PPlayer> = new AspectLookup();
    var cardAspectLookup(default, null):AspectLookup<PCard> = new AspectLookup();
    var spaceAspectLookup(default, null):AspectLookup<PSpace> = new AspectLookup();

    public function new():Void {}

    public inline function onGlobal(prop:AspectProperty<PGlobal>) return globalAspectLookup[prop.id];
    public inline function onPlayer(prop:AspectProperty<PPlayer>) return playerAspectLookup[prop.id];
    public inline function onCard(prop:AspectProperty<PCard>) return cardAspectLookup[prop.id];
    public inline function onSpace(prop:AspectProperty<PSpace>) return spaceAspectLookup[prop.id];

    public inline function globalDefaults():Global return globalAspectTemplate.copy();
    public inline function playerDefaults():Player return playerAspectTemplate.copy();
    public inline function cardDefaults():Card return cardAspectTemplate.copy();
    public inline function spaceDefaults():Space return spaceAspectTemplate.copy();
}
