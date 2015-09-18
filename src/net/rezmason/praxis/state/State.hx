package net.rezmason.praxis.state;

import net.rezmason.praxis.PraxisTypes;
import net.rezmason.grid.Grid;

@:allow(net.rezmason.praxis.state)
class State {

    public var global(get, null):Global;
    
    public var globals(default, null):Array<Global>;
    public var players(default, null):Array<Player>;
    public var cards(default, null):Array<Card>;
    public var spaces(default, null):Array<Space>;
    public var extras(default, null):Array<Extra>;
    
    var cells:BoardGrid;
    
    public function new():Void {
        globals = [];
        players = [];
        cards   = [];
        spaces  = [];
        cells   = new Grid();
        extras  = [];
    }

    function wipe():Void {
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

    public inline function getCell(index) return cells.getCell(index);
    public inline function eachCell() return cells.iterator();
    public inline function numCells() return cells.length; // should be the same as numSpaces though

    @:allow(net.rezmason.praxis.rule.Builder)
    inline function addGlobal(template, ident):Global return addAspectPointable(template, ident, globals);

    @:allow(net.rezmason.praxis.rule.Builder)
    inline function addPlayer(template, ident):Player return addAspectPointable(template, ident, players);

    @:allow(net.rezmason.praxis.rule.Builder)
    inline function addCard(template, ident):Card return addAspectPointable(template, ident, cards);

    @:allow(net.rezmason.praxis.rule.Builder)
    inline function addSpace(template, ident):Space {
        var space = addAspectPointable(template, ident, spaces);
        cells.addCell(space);
        return space;
    }

    @:allow(net.rezmason.praxis.rule.Builder)
    inline function addExtra(template, ident):Extra return addAspectPointable(template, ident, extras);

    inline function addAspectPointable<T>(template:AspectPointable<T>, ident, list):AspectPointable<T> {
        template[ident] = list.length;
        list.push(template);
        return template;
    }
}
