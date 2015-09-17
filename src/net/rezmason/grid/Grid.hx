package net.rezmason.grid;

import haxe.Serializer;
import haxe.Unserializer;
import net.rezmason.grid.GridUtils.allDirections;

class Grid<T> {

    static var ids = 0;

    public var id = ids++;

    var cells:Array<Cell<T>>;
    public var length(get, null):UInt;
    public inline function new() cells = [];
    public inline function wipe() cells.splice(0, cells.length);
    public inline function addCell(value:T):Cell<T> {
        var cell = new Cell(cells.length, value);
        cells.push(cell);
        return cell;
    }
    public inline function getCell(id:UInt):Cell<T> return cells[id];
    public inline function copyFrom(other:Grid<T>) cells = other.cells.copy();
    public inline function iterator() return cells.iterator();
    inline function get_length() return cells.length;

    @:keep
    function hxSerialize(s:Serializer) {
        s.serialize(cells.length);
        for (cell in cells) s.serialize(cell.value);
        for (cell in cells) {
            var neighborIDs = [];
            for (direction in allDirections()) {
                var neighbor = cell.neighbors[direction];
                neighborIDs.push(neighbor == null ? -1 : neighbor.id);
            }
            s.serialize(neighborIDs);
        }
    }

    @:keep
    function hxUnserialize(u:Unserializer) {
        cells = [];
        var numCells:UInt = u.unserialize();
        for (ike in 0...numCells) addCell(u.unserialize());
        for (ike in 0...numCells) {
            var cell = cells[ike];
            var neighborIDs:Array<Int> = u.unserialize();
            for (direction in allDirections()) {
                if (neighborIDs[direction] == -1) continue;
                cell.neighbors[direction] = cells[neighborIDs[direction]];
            }
        }
    }
}
