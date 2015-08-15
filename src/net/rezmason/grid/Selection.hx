package net.rezmason.grid;

import net.rezmason.ds.ShitList;
import net.rezmason.grid.GridUtils.orthoNeighbors;
typedef SpreadFilter<T> = T->T->Bool;

abstract Selection<T>(Array<Cell<T>>) {
    public inline function new() this = [];
    public inline function add(cell:Cell<T>) if (cell != null) this[cell.id] = cell;
    public inline function contains(id:UInt) return this[id] != null;

    public inline function expand(orthoOnly:Bool = false, spreadFilter:SpreadFilter<T> = null):Selection<T> {
        var expansion = new Selection();
        var newCells:ShitList<Cell<T>> = new ShitList();
        for (cell in iterator()) {
            expansion.add(cell);
            newCells.add(cell);
        }

        var cell:Cell<T> = newCells.pop();
        while (cell != null) {

            var neighbors:Array<Cell<T>> = orthoOnly ? orthoNeighbors(cell) : cell.neighbors;

            for (neighbor in neighbors) {
                if (neighbor != null && !expansion.contains(neighbor.id) && (spreadFilter == null || spreadFilter(neighbor.value, cell.value))) {
                    expansion.add(neighbor);
                    newCells.add(neighbor);
                }
            }
            cell = newCells.pop();
        }

        return expansion;
    }

    public inline function iterator() {
        var itr = this.iterator();
        function next() {
            var cell = null;
            while (cell == null) cell = itr.next();
            return cell;
        }
        return {hasNext:itr.hasNext, next:next};
    }
   
}
