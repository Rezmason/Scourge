package net.rezmason.praxis.state;

import net.rezmason.praxis.PraxisTypes;
import net.rezmason.grid.Grid;

class State {

    public var global(get, null):Global;
    public var globals(default, null):Array<Global>;
    public var players(default, null):Array<Player>;
    public var cards(default, null):Array<Card>;
    public var spaces(default, null):Array<Space>;
    public var cells(default, null):BoardGrid;
    public var extras(default, null):Array<Extra>;
    
    public function new():Void {
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
        cells = new Grid();
    }

    inline function get_global() return globals[0];
}
