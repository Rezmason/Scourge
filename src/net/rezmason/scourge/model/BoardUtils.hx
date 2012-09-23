package net.rezmason.scourge.model;

import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.GridNode;
import net.rezmason.scourge.model.aspects.FreshnessAspect;
import net.rezmason.scourge.model.aspects.OwnershipAspect;

using Lambda;
using net.rezmason.scourge.model.GridUtils;
using net.rezmason.utils.Pointers;

class BoardUtils {

    private static var ADD_SPACES:EReg = ~/([^\n\t])/g;

    public static function freshen(state:State, freshness_:AspectPtr, east:Int, south:Int, value:Int = 1):Void {
        var node:BoardNode = state.nodes[0].run(Gr.nw).run(Gr.w).run(Gr.n).run(Gr.s, south).run(Gr.e, east);
        node.value.mod(freshness_, value);
    }

    public static function spitBoard(state:State, plan:StatePlan, addSpaces:Bool = true, otherNodeAspects:IntHash<String> = null):String {

        if (state.nodes.length == 0) return "empty grid";

        if (otherNodeAspects == null) otherNodeAspects = new IntHash<String>();
        var otherAspectPtrs:IntHash<AspectPtr> = new IntHash<AspectPtr>();
        for (id in otherNodeAspects.keys()) otherAspectPtrs.set(id, plan.nodeAspectLookup[id]);

        var str:String = "";

        var grid:BoardNode = state.nodes[0].run(Gr.nw).run(Gr.w).run(Gr.n);

        var occupier_:AspectPtr = plan.nodeAspectLookup[OwnershipAspect.OCCUPIER.id];
        var isFilled_:AspectPtr = plan.nodeAspectLookup[OwnershipAspect.IS_FILLED.id];

        for (row in grid.walk(Gr.s)) {
            str += "\n";
            for (column in row.walk(Gr.e)) {

                var otherAspectFound:Bool = false;

                for (id in otherAspectPtrs.keys()) {
                    var ptr:AspectPtr = otherAspectPtrs.get(id);
                    if (column.value.at(ptr) > 0) {
                        otherAspectFound = true;
                        str += otherNodeAspects.get(id);
                        break;
                    }
                }

                if (!otherAspectFound) {
                    var occupier:Null<Int> = column.value.at(occupier_);
                    var isFilled:Null<Int> = column.value.at(isFilled_);

                    str += switch (true) {
                        case (occupier == null): "n";
                        case (occupier != Aspect.NULL): "" + occupier;
                        case (isFilled == 1): "X";
                        default: " ";
                    }
                }
            }
        }

        if (addSpaces) str = ADD_SPACES.replace(str, "$1 ");

        return str;
    }

    public inline static function iterate(_node:BoardNode, _nodes:Array<BoardNode>, _aspectPointer:AspectPtr):BoardNodeIterator {
        return new BoardNodeIterator(_node, _nodes, _aspectPointer);
    }

    public inline static function boardListToArray(_node:BoardNode, _nodes:Array<BoardNode>, _aspectPointer:AspectPtr):Array<BoardNode> {
        var arr:Array<BoardNode> = [];
        for (node in iterate(_node, _nodes, _aspectPointer)) arr.push(node);
        return arr;
    }

    public inline static function removeNode(node:BoardNode, nodes:Array<BoardNode>, next:AspectPtr, prev:AspectPtr):BoardNode {
        var nextNodeID:Int = node.value.at(next);
        var prevNodeID:Int = node.value.at(prev);

        var nextNode:BoardNode = null;

        var wasConnected:Bool = false;

        if (nextNodeID != Aspect.NULL) {
            wasConnected = true;
            nextNode = nodes[nextNodeID];
            nodes[nextNodeID].value.mod(prev, prevNodeID);
        }

        if (prevNodeID != Aspect.NULL) {
            wasConnected = true;
            nodes[prevNodeID].value.mod(next, nextNodeID);
        }

        if (wasConnected) {
            node.value.mod(next, Aspect.NULL);
            node.value.mod(prev, Aspect.NULL);
        }

        return nextNode;
    }

    public inline static function addNode(node:BoardNode, addedNode:BoardNode, nodes:Array<BoardNode>, id:AspectPtr, next:AspectPtr, prev:AspectPtr):BoardNode {
        removeNode(addedNode, nodes, next, prev);

        var prevNodeID:Int = node.value.at(prev);
        var addedNodeID:Int = addedNode.value.at(id);

        addedNode.value.mod(next, node.value.at(id));
        addedNode.value.mod(prev, prevNodeID);
        node.value.mod(prev, addedNodeID);
        if (prevNodeID != Aspect.NULL) {
            var prevNode:BoardNode = nodes[prevNodeID];
            prevNode.value.mod(next, addedNodeID);
        }

        return addedNode;
    }

    public inline static function chainByAspect(nodes:Array<BoardNode>, id:AspectPtr, next:AspectPtr, prev:AspectPtr):Void {
        nodes = nodes.copy();
        while (nodes.remove(null)) {}

        var node:BoardNode = nodes[0];

        for (ike in 1...nodes.length) {
            var nextNode:BoardNode = nodes[ike];
            node.value.mod(next, nextNode.value.at(id));
            nextNode.value.mod(prev, node.value.at(id));
            node = nextNode;
        }

        node.value.mod(next, Aspect.NULL);
        node = nodes[0];
        node.value.mod(prev, Aspect.NULL);
    }
}

class BoardNodeIterator {

    private var node:BoardNode;
    private var nodes:Array<BoardNode>;
    private var aspectPointer:AspectPtr;

    public function new(_node:BoardNode, _nodes:Array<BoardNode>, _aspectPointer:AspectPtr):Void {
        node = _node;
        nodes = _nodes;
        aspectPointer = _aspectPointer;
    }

    public function hasNext():Bool {
        return node != null;
    }

    public function next():BoardNode {
        var lastNode:BoardNode = node;
        var nodeIndex:Int = node.value.at(aspectPointer);
        if (nodeIndex == Aspect.NULL) node = null;
        else node = nodes[nodeIndex];
        return lastNode;
    }
}
