package net.rezmason.praxis.state;

import net.rezmason.praxis.PraxisTypes;
import net.rezmason.praxis.grid.GridLocus;
using net.rezmason.praxis.grid.GridUtils;
using net.rezmason.utils.Pointers;

class State {

    public var global(default, null):AspectSet;
    public var globals(default, null):Array<AspectSet>;
    public var players(default, null):Array<AspectSet>;
    public var nodes(default, null):Array<AspectSet>;
    public var loci(default, set):Array<GridLocus<AspectSet>>; // aka BoardLocus
    public var extras(default, null):Array<AspectSet>;
    public var key(default, set):PtrKey;

    public function new(key:PtrKey):Void {
        this.key = key;
        globals = [];
        players = [];
        nodes   = [];
        loci    = [];
        extras  = [];
    }

    public function wipe():Void {
        global = null;
        globals.splice(0, globals.length);
        players.splice(0, players.length);
        nodes.splice  (0, nodes.length);
        loci.splice   (0, loci.length);
        extras.splice (0, extras.length);
    }

    function hxSerialize(s:haxe.Serializer):Void {
        s.serialize(globals);
        s.serialize(players);
        s.serialize(nodes);
        s.serialize(extras);
    }

    function hxUnserialize(s:haxe.Unserializer):Void {
        globals = s.unserialize();
        players = s.unserialize();
        nodes   = s.unserialize();
        extras  = s.unserialize();
        resolve();
    }

    public function set_key(val:PtrKey):PtrKey {
        if (key == null) key = val;
        return val;
    }

    public function set_loci(val:Array<GridLocus<AspectSet>>):Array<GridLocus<AspectSet>> {
        if (loci == null) loci = val;
        return val;
    }

    public function resolve() {
        global = globals[0];
        loci = [];
    }
}
