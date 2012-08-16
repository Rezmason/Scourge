package net.rezmason.scourge.model;

import net.rezmason.scourge.model.GridNode;

using Lambda;

class GridUtils {

    // Creates an iterator for walking along a grid in one direction
    public inline static function walk<T> (node:GridNode<T>, direction:Int):GridWalker<T> {
        return new GridWalker<T>(node, direction);
    }

    public inline static function allDirections():Iterator<Int> { return 0...8; }

    // Returns the furthest reachable node from the given node in the specified direction
    public inline static function run<T> (node:GridNode<T>, direction:Int, maxDist:Int = -1):GridNode<T> {
        var distance:Int = 0;
        while (node.neighbors[direction] != null && distance != maxDist) {
            node = node.neighbors[direction];
            distance++;
        }
        return node;
    }

    public inline static function attach<T> (node1:GridNode<T>, node2:GridNode<T>, direction:Int):GridNode<T> {
        if (node1 != null) node1.neighbors[direction] = node2;
        if (node2 != null) node2.neighbors[(direction + 4) % 8] = node1;
        return node2;
    }

    public inline static function getGraph<T>(node:GridNode<T>):Array<GridNode<T>> {
        var nodes:Array<GridNode<T>> = [];
        var newNodes:Array<GridNode<T>> = [];

        while (node != null) {
            for (neighbor in node.neighbors) {
                if (neighbor != null && !nodes.has(neighbor)) {
                    nodes.push(neighbor);
                    newNodes.push(neighbor);
                }
            }
            node = newNodes.pop();
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
