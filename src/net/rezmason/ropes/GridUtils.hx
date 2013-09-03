package net.rezmason.ropes;

import haxe.Serializer;
import haxe.Unserializer;
import net.rezmason.ropes.GridNode;

using Lambda;
using net.rezmason.utils.MapUtils;

typedef SpreadFilter<T> = T->T->Bool;

class GridUtils {

    // Creates an iterator for walking along a grid in one direction
    public inline static function walk<T> (node:GridNode<T>, direction:Int):GridWalker<T> {
        return new GridWalker<T>(node, direction);
    }

    public inline static function allDirections():Iterator<Int> { return 0...8; }

    public inline static function orthoDirections():Iterator<Int> { return [0, 2, 4, 6].iterator(); }

    // Returns the furthest reachable node from the given node in the specified direction
    public inline static function run<T> (node:GridNode<T>, direction:Int, maxDist:Int = -1):GridNode<T> {
        var distance:Int = 0;
        while (node.neighbors[direction] != null && distance != maxDist) {
            node = node.neighbors[direction];
            distance++;
        }
        return node;
    }

    public inline static function attach<T> (node1:GridNode<T>, node2:GridNode<T>, directionForward:Int, directionBack:Int = -1):GridNode<T> {
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

    public inline static function allNeighbors<T>(node:GridNode<T>):Array<GridNode<T>> {
        return node.neighbors;
    }

    public inline static function orthoNeighbors<T>(node:GridNode<T>):Array<GridNode<T>> {
        return [n(node), e(node), s(node), w(node)];
    }

    public inline static function getGraph<T>(source:GridNode<T>, orthoOnly:Bool = false, spreadFilter:SpreadFilter<T> = null):Map<Int, GridNode<T>> {
        return expandGraph([source.id => source], orthoOnly, spreadFilter);
    }

    public inline static function expandGraph<T>(sources:Map<Int, GridNode<T>>, orthoOnly:Bool = false, spreadFilter:SpreadFilter<T> = null):Map<Int, GridNode<T>> {
        var nodes:Map<Int, GridNode<T>> = new Map();
        nodes.absorb(sources);
        var newNodes:List<GridNode<T>> = sources.list();

        var node:GridNode<T> = newNodes.pop();
        while (node != null) {

            var neighbors:Array<GridNode<T>> = orthoOnly ? orthoNeighbors(node) : node.neighbors;

            for (neighbor in neighbors) {
                if (neighbor != null && !nodes.exists(neighbor.id) && (spreadFilter == null || spreadFilter(neighbor.value, node.value))) {
                    nodes[neighbor.id] = neighbor;
                    newNodes.add(neighbor);
                }
            }
            node = newNodes.pop();
        }

        return nodes;
    }

    public inline static function getGraphSequence<T>(source:GridNode<T>, orthoOnly:Bool = false, spreadFilter:SpreadFilter<T> = null):Array<GridNode<T>> {
        return expandGraphSequence([source], orthoOnly, spreadFilter);
    }

    public inline static function expandGraphSequence<T>(sources:Array<GridNode<T>>, orthoOnly:Bool = false, spreadFilter:SpreadFilter<T> = null):Array<GridNode<T>> {
        var nodes:Array<GridNode<T>> = sources.copy();
        var newNodes:List<GridNode<T>> = sources.list();

        var nodesByID:Map<Int, GridNode<T>> = new Map();
        for (node in nodes) nodesByID[node.id] = node;

        var node:GridNode<T> = newNodes.pop();
        while (node != null) {

            var neighbors:Array<GridNode<T>> = orthoOnly ? orthoNeighbors(node) : node.neighbors;

            for (neighbor in neighbors) {
                if (neighbor != null && !nodesByID.exists(neighbor.id) && (spreadFilter == null || spreadFilter(neighbor.value, node.value))) {
                    nodes.push(neighbor);
                    newNodes.add(neighbor);
                    nodesByID[neighbor.id] = neighbor;
                }
            }
            node = newNodes.pop();
        }

        return nodes;
    }

    public inline static function serializeGrid<T>(s:Serializer, sourceList:Array<GridNode<T>>):Void {
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

    public inline static function unserializeGrid<T>(s:Unserializer):Array<GridNode<T>> {
        var data:Array<Array<Dynamic>> = s.unserialize();

        var nodes:Array<GridNode<T>> = [];

        for (ike in 0...data.length) nodes.push(new GridNode<T>(ike, data[ike][0]));
        for (ike in 0...nodes.length) {
            var neighbors:Array<Null<Int>> = data[ike][1];
            var headingOffsets:Array<Null<Int>> = data[ike][2];
            var node:GridNode<T> = nodes[ike];
            for (ike in 0...neighbors.length) if (neighbors[ike] != -1) node.neighbors[ike] = nodes[neighbors[ike]];
            for (ike in 0...headingOffsets.length) node.headingOffsets[ike] = headingOffsets[ike];
        }

        return nodes;
    }

    // Shortcuts
    public inline static function nw<T> (node:GridNode<T>):GridNode<T> { return node.neighbors[Gr.nw]; }
    public inline static function  n<T> (node:GridNode<T>):GridNode<T> { return node.neighbors[Gr.n ]; }
    public inline static function ne<T> (node:GridNode<T>):GridNode<T> { return node.neighbors[Gr.ne]; }
    public inline static function  e<T> (node:GridNode<T>):GridNode<T> { return node.neighbors[Gr.e ]; }
    public inline static function se<T> (node:GridNode<T>):GridNode<T> { return node.neighbors[Gr.se]; }
    public inline static function  s<T> (node:GridNode<T>):GridNode<T> { return node.neighbors[Gr.s ]; }
    public inline static function sw<T> (node:GridNode<T>):GridNode<T> { return node.neighbors[Gr.sw]; }
    public inline static function  w<T> (node:GridNode<T>):GridNode<T> { return node.neighbors[Gr.w ]; }
}

class GridWalker<T> {

    var node:GridNode<T>;
    var direction:Int;

    public function new(_node:GridNode<T>, _direction:Int):Void {
        node = _node;
        direction = _direction;
    }

    public function hasNext():Bool {
        return node != null;
    }

    public function next():GridNode<T> {
        var lastNode:GridNode<T> = node;
        node = node.neighbors[direction];
        return lastNode;
    }

}
