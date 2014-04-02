package net.rezmason.ropes;

import haxe.Serializer;
import haxe.Unserializer;
import net.rezmason.ropes.GridLocus;
import net.rezmason.ds.ShitList;

using Lambda;
using net.rezmason.utils.MapUtils;

typedef SpreadFilter<T> = T->T->Bool;

class GridUtils {

    // Creates an iterator for walking along a grid in one direction
    public inline static function walk<T> (node:GridLocus<T>, direction:Int):GridWalker<T> {
        return new GridWalker<T>(node, direction);
    }

    public inline static function allDirections():Iterator<Int> { return 0...8; }

    public inline static function orthoDirections():Iterator<Int> { return [0, 2, 4, 6].iterator(); }

    // Returns the furthest reachable node from the given node in the specified direction
    public inline static function run<T> (node:GridLocus<T>, direction:Int, maxDist:Int = -1):GridLocus<T> {
        var distance:Int = 0;
        while (node.neighbors[direction] != null && distance != maxDist) {
            node = node.neighbors[direction];
            distance++;
        }
        return node;
    }

    public inline static function attach<T> (node1:GridLocus<T>, node2:GridLocus<T>, directionForward:Int, directionBack:Int = -1):GridLocus<T> {
        if (node1 != null) {
            node1.neighbors[directionForward] = node2;
            node1.headingOffsets[directionForward] = 0;
        }
        if (node2 != null) {
            if (directionBack == -1) directionBack = (directionForward + 4) % 8;
            node2.neighbors[directionBack] = node1;
            node1.headingOffsets[directionBack] = 0;
        }
        return node2;
    }

    public inline static function orthoNeighbors<T>(node:GridLocus<T>):Array<GridLocus<T>> {
        if (node._orthoNeighbors == null) node._orthoNeighbors = [n(node), e(node), s(node), w(node)];
        return node._orthoNeighbors;
    }

    public inline static function diagNeighbors<T>(node:GridLocus<T>):Array<GridLocus<T>> {
        if (node._diagNeighbors == null) node._diagNeighbors = [ne(node), se(node), sw(node), nw(node)];
        return node._diagNeighbors;
    }

    public inline static function getGraph<T>(source:GridLocus<T>, orthoOnly:Bool = false, spreadFilter:SpreadFilter<T> = null):Array<GridLocus<T>> {
        return expandGraph([source], orthoOnly, spreadFilter);
    }

    public inline static function expandGraph<T>(sources:Array<GridLocus<T>>, orthoOnly:Bool = false, spreadFilter:SpreadFilter<T> = null):Array<GridLocus<T>> {
        var nodes:Array<GridLocus<T>> = [];
        for (node in sources) nodes[node.id] = node;
        var newNodes:ShitList<GridLocus<T>> = new ShitList(sources);

        var node:GridLocus<T> = newNodes.pop();
        while (node != null) {

            var neighbors:Array<GridLocus<T>> = orthoOnly ? orthoNeighbors(node) : node.neighbors;

            for (neighbor in neighbors) {
                if (neighbor != null && nodes[neighbor.id] == null && (spreadFilter == null || spreadFilter(neighbor.value, node.value))) {
                    nodes[neighbor.id] = neighbor;
                    newNodes.add(neighbor);
                }
            }
            node = newNodes.pop();
        }

        return nodes;
    }

    public inline static function getGraphSequence<T>(source:GridLocus<T>, orthoOnly:Null<Bool> = false, spreadFilter:SpreadFilter<T> = null):Array<GridLocus<T>> {
        return expandGraphSequence([source], orthoOnly, spreadFilter);
    }

    public inline static function expandGraphSequence<T>(sources:Array<GridLocus<T>>, orthoOnly:Bool = false, spreadFilter:SpreadFilter<T> = null):Array<GridLocus<T>> {
        var nodes:Array<GridLocus<T>> = sources.copy();
        var newNodes:ShitList<GridLocus<T>> = new ShitList(sources);

        var nodesByID:Array<GridLocus<T>> = [];
        for (node in nodes) nodesByID[node.id] = node;

        var node:GridLocus<T> = newNodes.pop();
        while (node != null) {

            var neighbors:Array<GridLocus<T>> = orthoOnly ? orthoNeighbors(node) : node.neighbors;

            for (neighbor in neighbors) {
                if (neighbor != null && nodesByID[neighbor.id] == null && (spreadFilter == null || spreadFilter(neighbor.value, node.value))) {
                    nodes.push(neighbor);
                    newNodes.add(neighbor);
                    nodesByID[neighbor.id] = neighbor;
                }
            }
            node = newNodes.pop();
        }

        return nodes;
    }

    public inline static function serializeGrid<T>(s:Serializer, sourceList:Array<GridLocus<T>>):Void {
        var data:Array<Array<Dynamic>> = [];

        for (node in sourceList) {
            var neighbors:Array<Null<Int>> = [];
            for (ike in 0...node.neighbors.length) {
                if (node.neighbors[ike] != null) neighbors[ike] = node.neighbors[ike].id;
                else neighbors[ike] = -1;
            }
            data.push([node.value, neighbors, node.headingOffsets]);
        }

        s.serialize(data);
    }

    public inline static function unserializeGrid<T>(s:Unserializer):Array<GridLocus<T>> {
        var data:Array<Array<Dynamic>> = s.unserialize();

        var nodes:Array<GridLocus<T>> = [];

        for (ike in 0...data.length) nodes.push(new GridLocus<T>(ike, data[ike][0]));
        for (ike in 0...nodes.length) {
            var neighbors:Array<Null<Int>> = data[ike][1];
            var headingOffsets:Array<Null<Int>> = data[ike][2];
            var node:GridLocus<T> = nodes[ike];
            for (ike in 0...neighbors.length) if (neighbors[ike] != -1) node.neighbors[ike] = nodes[neighbors[ike]];
            for (ike in 0...headingOffsets.length) node.headingOffsets[ike] = headingOffsets[ike];
        }

        return nodes;
    }

    // Shortcuts
    public inline static function nw<T> (node:GridLocus<T>):GridLocus<T> { return node.neighbors[Gr.nw]; }
    public inline static function  n<T> (node:GridLocus<T>):GridLocus<T> { return node.neighbors[Gr.n ]; }
    public inline static function ne<T> (node:GridLocus<T>):GridLocus<T> { return node.neighbors[Gr.ne]; }
    public inline static function  e<T> (node:GridLocus<T>):GridLocus<T> { return node.neighbors[Gr.e ]; }
    public inline static function se<T> (node:GridLocus<T>):GridLocus<T> { return node.neighbors[Gr.se]; }
    public inline static function  s<T> (node:GridLocus<T>):GridLocus<T> { return node.neighbors[Gr.s ]; }
    public inline static function sw<T> (node:GridLocus<T>):GridLocus<T> { return node.neighbors[Gr.sw]; }
    public inline static function  w<T> (node:GridLocus<T>):GridLocus<T> { return node.neighbors[Gr.w ]; }
}

class GridWalker<T> {

    var node:GridLocus<T>;
    var direction:Int;

    public function new(_node:GridLocus<T>, _direction:Int):Void {
        node = _node;
        direction = _direction;
    }

    public function hasNext():Bool {
        return node != null;
    }

    public function next():GridLocus<T> {
        var lastNode:GridLocus<T> = node;
        node = node.neighbors[direction];
        return lastNode;
    }

}
