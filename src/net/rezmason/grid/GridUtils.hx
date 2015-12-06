package net.rezmason.grid;

import net.rezmason.grid.GridDirection.*;
import net.rezmason.utils.SkipIterator;

class GridUtils {

    // Creates an iterator for walking along a grid in one direction
    public inline static function walk<T> (cell:Cell<T>, direction:Int):GridWalker<T> {
        return new GridWalker<T>(cell, direction);
    }

    public inline static function allDirections():Iterator<Int> { return 0...8; }

    public inline static function orthoDirections():Iterator<Int> { return new SkipIterator(0, 8, 2); }

    // Returns the furthest reachable cell from the given cell in the specified direction
    public inline static function run<T> (cell:Cell<T>, direction:Int, maxDist:Int = -1, validator:Cell<T>->Bool = null):Cell<T> {
        var distance:Int = 0;
        while (distance != maxDist) {
            if (cell.neighbors[direction] == null) break;
            if (validator != null && !validator(cell.neighbors[direction])) break;
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

    public inline static function select<T>(cells:Array<Cell<T>>) {
        var selection = new Selection();
        for (cell in cells) selection.add(cell);
        return selection;
    }

    public inline static function runEuclidean<T>(cell:Cell<T>, dx:Int, dy:Int):Cell<T> {
        var dn:Int = 0;
        var dw:Int = 0;
        var de:Int = -dx; // TODO: fix tests so these can be made positive
        var ds:Int = -dy;

        if (de < 0) {
            dw = -de;
            de = 0;
        }

        if (ds < 0) {
            dn = -ds;
            ds = 0;
        }
        cell = run(cell, N, dn);
        cell = run(cell, S, ds);
        cell = run(cell, E, de);
        cell = run(cell, W, dw);
        return cell;
    }


    // Shortcuts
    public inline static function nw<T> (cell:Cell<T>):Cell<T> { return cell.neighbors[NW]; }
    public inline static function  n<T> (cell:Cell<T>):Cell<T> { return cell.neighbors[N ]; }
    public inline static function ne<T> (cell:Cell<T>):Cell<T> { return cell.neighbors[NE]; }
    public inline static function  e<T> (cell:Cell<T>):Cell<T> { return cell.neighbors[E ]; }
    public inline static function se<T> (cell:Cell<T>):Cell<T> { return cell.neighbors[SE]; }
    public inline static function  s<T> (cell:Cell<T>):Cell<T> { return cell.neighbors[S ]; }
    public inline static function sw<T> (cell:Cell<T>):Cell<T> { return cell.neighbors[SW]; }
    public inline static function  w<T> (cell:Cell<T>):Cell<T> { return cell.neighbors[W ]; }
}

class GridWalker<T> {

    var cell:Cell<T>;
    var direction:Int;

    public function new(cell:Cell<T>, direction:Int):Void {
        this.cell = cell;
        this.direction = direction;
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
