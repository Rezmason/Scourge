package net.rezmason.ropes;

import net.rezmason.ropes.RopesTypes;

using net.rezmason.ropes.GridUtils;
using net.rezmason.utils.Pointers;

class State {

    public var aspects:AspectSet;
    public var players(default, null):Array<AspectSet>;
    public var nodes(default, null):Array<AspectSet>;
    public var loci(default, null):Array<GridLocus<AspectSet>>; // aka BoardLocus
    public var extras(default, null):Array<AspectSet>;
    public var key(default, set):PtrKey;

    public function new(key:PtrKey):Void {

        this.key = key;

        aspects = null;
        players = [];
        nodes   = [];
        loci    = [];
        extras  = [];
    }

    public function wipe():Void {
        if (aspects != null) {
            aspects.wipe();
            aspects = null;
        }
        players.splice(0, players.length);
        nodes.splice  (0, nodes.length);
        loci.splice  (0, loci.length);
        extras.splice (0, extras.length);
    }

    function hxSerialize(s:haxe.Serializer):Void {
        s.serialize(aspects);
        s.serialize(players);
        s.serializeGrid(loci); // implicitly serializes nodes
        s.serialize(extras);
    }

    function hxUnserialize(s:haxe.Unserializer):Void {
        aspects = s.unserialize();
        players = s.unserialize();
        loci    = s.unserializeGrid();
        extras  = s.unserialize();

        nodes = [];
        for (locus in loci) nodes.push(locus.value);
    }

    public function set_key(val:PtrKey):PtrKey {
        if (key == null) key = val;
        return val;
    }
}
