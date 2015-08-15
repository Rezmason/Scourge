package net.rezmason.grid;

import net.rezmason.grid.GridDirection.*;
import net.rezmason.ds.ShitList;
import net.rezmason.utils.SkipIterator;

using Lambda;
using net.rezmason.utils.MapUtils;

typedef SpreadFilter<T> = T->T->Bool;

class GridUtils {

    // Creates an iterator for walking along a grid in one direction
    public inline static function walk<T> (cell:Cell<T>, direction:Int):GridWalker<T> {
        return new GridWalker<T>(cell, direction);
    }

    public inline static function allDirections():Iterator<Int> { return 0...8; }

    public inline static function orthoDirections():Iterator<Int> { return new SkipIterator(0, 8, 2); }

    // Returns the furthest reachable cell from the given cell in the specified direction
    public inline static function run<T> (cell:Cell<T>, direction:Int, maxDist:Int = -1):Cell<T> {
        var distance:Int = 0;
        while (cell.neighbors[direction] != null && distance != maxDist) {
            cell = cell.neighbors[direction];
            distance++;
        }
        return cell;
    }

    public inline static function attach<T> (cell1:Cell<T>, cell2:Cell<T>, directionForward:Int, directionBack:Int = -1):Cell<T> {
        if (cell1 != null) {
            cell1.neighbors[directionForward] = cell2;
        }
        if (cell2 != null) {
            if (directionBack == -1) directionBack = (directionForward + 4) % 8;
            cell2.neighbors[directionBack] = cell1;
        }
        return cell2;
    }

    public inline static function orthoNeighbors<T>(cell:Cell<T>):Array<Cell<T>> {
        if (cell._orthoNeighbors == null) cell._orthoNeighbors = [n(cell), e(cell), s(cell), w(cell)];
        return cell._orthoNeighbors;
    }

    public inline static function diagNeighbors<T>(cell:Cell<T>):Array<Cell<T>> {
        if (cell._diagNeighbors == null) cell._diagNeighbors = [ne(cell), se(cell), sw(cell), nw(cell)];
        return cell._diagNeighbors;
    }

    public inline static function getGrid<T>(source:Cell<T>, orthoOnly:Bool = false, spreadFilter:SpreadFilter<T> = null):Array<Cell<T>> {
        return expandGrid([source], orthoOnly, spreadFilter);
    }

    public inline static function expandGrid<T>(sources:Array<Cell<T>>, orthoOnly:Bool = false, spreadFilter:SpreadFilter<T> = null):Array<Cell<T>> {
        var cells:Array<Cell<T>> = [];
        for (cell in sources) cells[cell.id] = cell;
        var newCells:ShitList<Cell<T>> = new ShitList(sources);

        var cell:Cell<T> = newCells.pop();
        while (cell != null) {

            var neighbors:Array<Cell<T>> = orthoOnly ? orthoNeighbors(cell) : cell.neighbors;

            for (neighbor in neighbors) {
                if (neighbor != null && cells[neighbor.id] == null && (spreadFilter == null || spreadFilter(neighbor.value, cell.value))) {
                    cells[neighbor.id] = neighbor;
                    newCells.add(neighbor);
                }
            }
            cell = newCells.pop();
        }

        return cells;
    }

    public inline static function getGridSequence<T>(source:Cell<T>, orthoOnly:Null<Bool> = false, spreadFilter:SpreadFilter<T> = null):Array<Cell<T>> {
        return expandGridSequence([source], orthoOnly, spreadFilter);
    }

    public inline static function expandGridSequence<T>(sources:Array<Cell<T>>, orthoOnly:Bool = false, spreadFilter:SpreadFilter<T> = null):Array<Cell<T>> {
        var cells:Array<Cell<T>> = sources.copy();
        var newCells:ShitList<Cell<T>> = new ShitList(sources);

        var cellsByID:Array<Cell<T>> = [];
        for (cell in cells) cellsByID[cell.id] = cell;

        var cell:Cell<T> = newCells.pop();
        while (cell != null) {

            var neighbors:Array<Cell<T>> = orthoOnly ? orthoNeighbors(cell) : cell.neighbors;

            for (neighbor in neighbors) {
                if (neighbor != null && cellsByID[neighbor.id] == null && (spreadFilter == null || spreadFilter(neighbor.value, cell.value))) {
                    cells.push(neighbor);
                    newCells.add(neighbor);
                    cellsByID[neighbor.id] = neighbor;
                }
            }
            cell = newCells.pop();
        }

        return cells;
    }

    // Shortcuts
    public inline static function nw<T> (cell:Cell<T>):Cell<T> { return cell.neighbors[cast NW]; }
    public inline static function  n<T> (cell:Cell<T>):Cell<T> { return cell.neighbors[cast N ]; }
    public inline static function ne<T> (cell:Cell<T>):Cell<T> { return cell.neighbors[cast NE]; }
    public inline static function  e<T> (cell:Cell<T>):Cell<T> { return cell.neighbors[cast E ]; }
    public inline static function se<T> (cell:Cell<T>):Cell<T> { return cell.neighbors[cast SE]; }
    public inline static function  s<T> (cell:Cell<T>):Cell<T> { return cell.neighbors[cast S ]; }
    public inline static function sw<T> (cell:Cell<T>):Cell<T> { return cell.neighbors[cast SW]; }
    public inline static function  w<T> (cell:Cell<T>):Cell<T> { return cell.neighbors[cast W ]; }
}

class GridWalker<T> {

    var cell:Cell<T>;
    var direction:Int;

    public function new(_cell:Cell<T>, _direction:Int):Void {
        cell = _cell;
        direction = _direction;
    }

    public function hasNext():Bool {
        return cell != null;
    }

    public function next():Cell<T> {
        var lastCell:Cell<T> = cell;
        cell = cell.neighbors[direction];
        return lastCell;
    }

}
