package net.rezmason.praxis.state;

import net.rezmason.ds.ReadOnlyArray;
import net.rezmason.praxis.PraxisTypes;
import net.rezmason.grid.Grid;

@:allow(net.rezmason.praxis.state)
class State {

    public var global(get, null):Global;
    public var globals(get, null):ReadOnlyArray<Global>;
    public var players(get, null):ReadOnlyArray<Player>;
    public var cards(get, null):ReadOnlyArray<Card>;
    public var spaces(get, null):ReadOnlyArray<Space>;
    public var extras(get, null):ReadOnlyArray<Extra>;

    var _globals:Array<Global>;
    var _players:Array<Player>;
    var _cards:Array<Card>;
    var _spaces:Array<Space>;
    var _extras:Array<Extra>;
    
    var cells:BoardGrid;
    
    public function new():Void {
        _globals = [];
        _players = [];
        _cards   = [];
        _spaces  = [];
        _extras  = [];
        cells    = new Grid();
    }

    function wipe():Void {
        global = null;
        _globals.splice(0, globals.length);
        _players.splice(0, players.length);
        _cards.splice  (0, cards.length);
        _spaces.splice (0, spaces.length);
        _extras.splice (0, extras.length);
        cells.wipe();
    }

    function hxSerialize(s:haxe.Serializer):Void {
        s.serialize(_globals);
        s.serialize(_players);
        s.serialize(_cards);
        s.serialize(_spaces);
        s.serialize(_extras);
    }

    function hxUnserialize(s:haxe.Unserializer):Void {
        _globals = s.unserialize();
        _players = s.unserialize();
        _cards   = s.unserialize();
        _spaces  = s.unserialize();
        _extras  = s.unserialize();
        cells = new Grid();
    }

    public inline function getCell(index) return cells.getCell(index);
    public inline function eachCell() return cells.iterator();
    public inline function numCells() return cells.length; // should be the same as numSpaces though

    @:allow(net.rezmason.praxis.rule.Builder)
    inline function addGlobal(template, ident):Global return addAspectPointable(template, ident, _globals);

    @:allow(net.rezmason.praxis.rule.Builder)
    inline function addPlayer(template, ident):Player return addAspectPointable(template, ident, _players);

    @:allow(net.rezmason.praxis.rule.Builder)
    inline function addCard(template, ident):Card return addAspectPointable(template, ident, _cards);

    @:allow(net.rezmason.praxis.rule.Builder)
    inline function addSpace(template, ident):Space {
        var space = addAspectPointable(template, ident, _spaces);
        cells.addCell(space);
        return space;
    }

    @:allow(net.rezmason.praxis.rule.Builder)
    inline function addExtra(template, ident):Extra return addAspectPointable(template, ident, _extras);

    inline function addAspectPointable<T>(template:AspectPointable<T>, ident, list):AspectPointable<T> {
        template[ident] = list.length;
        list.push(template);
        return template;
    }

    inline function get_global() return _globals[0];
    inline function get_globals() return _globals;
    inline function get_players() return _players;
    inline function get_cards() return _cards;
    inline function get_spaces() return _spaces;
    inline function get_extras() return _extras;
}
