package net.rezmason.ropes;

import net.rezmason.ropes.Types;

using net.rezmason.ropes.GridUtils;

class State {

    public var aspects(default, null):AspectSet;
    public var players(default, null):Array<AspectSet>;
    public var nodes(default, null):Array<GridNode<AspectSet>>; // aka BoardNode
    public var extras(default, null):Array<AspectSet>;

    public function new():Void {
        aspects = [];
        players = [];
        nodes   = [];
        extras  = [];
    }

    public function wipe():Void {
        aspects.splice(0, aspects.length);
        players.splice(0, players.length);
        nodes.splice  (0, nodes.length);
        extras.splice (0, extras.length);
    }

    function hxSerialize(s:haxe.Serializer):Void {
        s.serialize(aspects);
        s.serialize(players);
        s.serializeGrid(nodes);
        s.serialize(extras);
    }

    function hxUnserialize(s:haxe.Unserializer):Void {
        aspects = s.unserialize();
        players = s.unserialize();
        nodes   = s.unserializeGrid();
        extras  = s.unserialize();
    }
}
