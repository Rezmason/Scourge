package net.rezmason.praxis.state;

import net.rezmason.praxis.PraxisTypes;
import net.rezmason.grid.Grid;
using net.rezmason.grid.GridUtils;
using net.rezmason.utils.Pointers;

class State {

    public var global(default, null):AspectSet;
    public var globals(default, null):Array<AspectSet>;
    public var players(default, null):Array<AspectSet>;
    public var cards(default, null):Array<AspectSet>;
    public var spaces(default, null):Array<AspectSet>;
    public var cells(default, set):Grid<AspectSet>; // aka BoardGrid
    public var extras(default, null):Array<AspectSet>;
    public var key(default, set):PtrKey;

    public function new(key:PtrKey):Void {
        this.key = key;
        globals = [];
        players = [];
        cards   = [];
        spaces  = [];
        cells   = new Grid();
        extras  = [];
    }

    public function wipe():Void {
        global = null;
        globals.splice(0, globals.length);
        players.splice(0, players.length);
        cards.splice  (0, cards.length);
        spaces.splice (0, spaces.length);
        cells.wipe();
        extras.splice (0, extras.length);
    }

    function hxSerialize(s:haxe.Serializer):Void {
        s.serialize(globals);
        s.serialize(players);
        s.serialize(cards);
        s.serialize(spaces);
        s.serialize(extras);
    }

    function hxUnserialize(s:haxe.Unserializer):Void {
        globals = s.unserialize();
        players = s.unserialize();
        cards   = s.unserialize();
        spaces  = s.unserialize();
        extras  = s.unserialize();
        resolve();
    }

    public function set_key(val:PtrKey):PtrKey {
        if (key == null) key = val;
        return val;
    }

    public function set_cells(val:Grid<AspectSet>):Grid<AspectSet> {
        if (cells == null) cells = val;
        return val;
    }

    public function resolve() {
        global = globals[0];
        cells = new Grid();
    }
}
