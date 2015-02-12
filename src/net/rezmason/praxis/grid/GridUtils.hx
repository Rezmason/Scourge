package net.rezmason.praxis.grid;

import haxe.Serializer;
import haxe.Unserializer;
import net.rezmason.praxis.grid.GridDirection.*;
import net.rezmason.praxis.grid.GridLocus;
import net.rezmason.ds.ShitList;

using Lambda;
using net.rezmason.utils.MapUtils;

typedef SpreadFilter<T> = T->T->Bool;

class GridUtils {

    // Creates an iterator for walking along a grid in one direction
    public inline static function walk<T> (locus:GridLocus<T>, direction:Int):GridWalker<T> {
        return new GridWalker<T>(locus, direction);
    }

    public inline static function allDirections():Iterator<Int> { return 0...8; }

    public inline static function orthoDirections():Iterator<Int> { return [0, 2, 4, 6].iterator(); }

    // Returns the furthest reachable locus from the given locus in the specified direction
    public inline static function run<T> (locus:GridLocus<T>, direction:Int, maxDist:Int = -1):GridLocus<T> {
        var distance:Int = 0;
        while (locus.neighbors[direction] != null && distance != maxDist) {
            locus = locus.neighbors[direction];
            distance++;
        }
        return locus;
    }

    public inline static function attach<T> (locus1:GridLocus<T>, locus2:GridLocus<T>, directionForward:Int, directionBack:Int = -1):GridLocus<T> {
        if (locus1 != null) {
            locus1.neighbors[directionForward] = locus2;
            locus1.headingOffsets[directionForward] = 0;
        }
        if (locus2 != null) {
            if (directionBack == -1) directionBack = (directionForward + 4) % 8;
            locus2.neighbors[directionBack] = locus1;
            locus1.headingOffsets[directionBack] = 0;
        }
        return locus2;
    }

    public inline static function orthoNeighbors<T>(locus:GridLocus<T>):Array<GridLocus<T>> {
        if (locus._orthoNeighbors == null) locus._orthoNeighbors = [n(locus), e(locus), s(locus), w(locus)];
        return locus._orthoNeighbors;
    }

    public inline static function diagNeighbors<T>(locus:GridLocus<T>):Array<GridLocus<T>> {
        if (locus._diagNeighbors == null) locus._diagNeighbors = [ne(locus), se(locus), sw(locus), nw(locus)];
        return locus._diagNeighbors;
    }

    public inline static function getGraph<T>(source:GridLocus<T>, orthoOnly:Bool = false, spreadFilter:SpreadFilter<T> = null):Array<GridLocus<T>> {
        return expandGraph([source], orthoOnly, spreadFilter);
    }

    public inline static function expandGraph<T>(sources:Array<GridLocus<T>>, orthoOnly:Bool = false, spreadFilter:SpreadFilter<T> = null):Array<GridLocus<T>> {
        var loci:Array<GridLocus<T>> = [];
        for (locus in sources) loci[locus.id] = locus;
        var newLoci:ShitList<GridLocus<T>> = new ShitList(sources);

        var locus:GridLocus<T> = newLoci.pop();
        while (locus != null) {

            var neighbors:Array<GridLocus<T>> = orthoOnly ? orthoNeighbors(locus) : locus.neighbors;

            for (neighbor in neighbors) {
                if (neighbor != null && loci[neighbor.id] == null && (spreadFilter == null || spreadFilter(neighbor.value, locus.value))) {
                    loci[neighbor.id] = neighbor;
                    newLoci.add(neighbor);
                }
            }
            locus = newLoci.pop();
        }

        return loci;
    }

    public inline static function getGraphSequence<T>(source:GridLocus<T>, orthoOnly:Null<Bool> = false, spreadFilter:SpreadFilter<T> = null):Array<GridLocus<T>> {
        return expandGraphSequence([source], orthoOnly, spreadFilter);
    }

    public inline static function expandGraphSequence<T>(sources:Array<GridLocus<T>>, orthoOnly:Bool = false, spreadFilter:SpreadFilter<T> = null):Array<GridLocus<T>> {
        var loci:Array<GridLocus<T>> = sources.copy();
        var newLoci:ShitList<GridLocus<T>> = new ShitList(sources);

        var lociByID:Array<GridLocus<T>> = [];
        for (locus in loci) lociByID[locus.id] = locus;

        var locus:GridLocus<T> = newLoci.pop();
        while (locus != null) {

            var neighbors:Array<GridLocus<T>> = orthoOnly ? orthoNeighbors(locus) : locus.neighbors;

            for (neighbor in neighbors) {
                if (neighbor != null && lociByID[neighbor.id] == null && (spreadFilter == null || spreadFilter(neighbor.value, locus.value))) {
                    loci.push(neighbor);
                    newLoci.add(neighbor);
                    lociByID[neighbor.id] = neighbor;
                }
            }
            locus = newLoci.pop();
        }

        return loci;
    }

    public inline static function serializeGrid<T>(s:Serializer, sourceList:Array<GridLocus<T>>):Void {
        var data:Array<Array<Dynamic>> = [];

        for (locus in sourceList) {
            var neighbors:Array<Null<Int>> = [];
            for (ike in 0...locus.neighbors.length) {
                if (locus.neighbors[ike] != null) neighbors[ike] = locus.neighbors[ike].id;
                else neighbors[ike] = -1;
            }
            data.push([locus.value, neighbors, locus.headingOffsets]);
        }

        s.serialize(data);
    }

    public inline static function unserializeGrid<T>(s:Unserializer):Array<GridLocus<T>> {
        var data:Array<Array<Dynamic>> = s.unserialize();

        var loci:Array<GridLocus<T>> = [for (ike in 0...data.length) new GridLocus<T>(ike, data[ike][0])];

        for (ike in 0...loci.length) {
            var neighbors:Array<Null<Int>> = data[ike][1];
            var headingOffsets:Array<Null<Int>> = data[ike][2];
            var locus:GridLocus<T> = loci[ike];
            for (ike in 0...neighbors.length) if (neighbors[ike] != -1) locus.neighbors[ike] = loci[neighbors[ike]];
            for (ike in 0...headingOffsets.length) locus.headingOffsets[ike] = headingOffsets[ike];
        }

        return loci;
    }

    // Shortcuts
    public inline static function nw<T> (locus:GridLocus<T>):GridLocus<T> { return locus.neighbors[NW]; }
    public inline static function  n<T> (locus:GridLocus<T>):GridLocus<T> { return locus.neighbors[N ]; }
    public inline static function ne<T> (locus:GridLocus<T>):GridLocus<T> { return locus.neighbors[NE]; }
    public inline static function  e<T> (locus:GridLocus<T>):GridLocus<T> { return locus.neighbors[E ]; }
    public inline static function se<T> (locus:GridLocus<T>):GridLocus<T> { return locus.neighbors[SE]; }
    public inline static function  s<T> (locus:GridLocus<T>):GridLocus<T> { return locus.neighbors[S ]; }
    public inline static function sw<T> (locus:GridLocus<T>):GridLocus<T> { return locus.neighbors[SW]; }
    public inline static function  w<T> (locus:GridLocus<T>):GridLocus<T> { return locus.neighbors[W ]; }
}

class GridWalker<T> {

    var locus:GridLocus<T>;
    var direction:Int;

    public function new(_locus:GridLocus<T>, _direction:Int):Void {
        locus = _locus;
        direction = _direction;
    }

    public function hasNext():Bool {
        return locus != null;
    }

    public function next():GridLocus<T> {
        var lastLocus:GridLocus<T> = locus;
        locus = locus.neighbors[direction];
        return lastLocus;
    }

}
