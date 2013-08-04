package net.rezmason.scourge.controller;

import net.rezmason.ropes.Types.Move;

class Operation {

    var filters:Map<String, Move->String->Bool>;
    public var index(default, null):Int;
    public var params(get, null):Iterator<String>;

    public function new(index:Int, filters:Map<String, Move->String->Bool>):Void {
        this.index = index;
        this.filters = filters;
    }

    private inline function get_params():Iterator<String>  return filters.keys();
    public inline function hasParam(param:String):Bool return filters.exists(param);

    public inline function applyFilter(param:String, value:String, moves:Array<Move>):Array<Move> {
        return moves.filter(filters[param].bind(_, value));
    }
}
