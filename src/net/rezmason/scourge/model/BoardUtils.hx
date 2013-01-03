package net.rezmason.scourge.model;

import net.rezmason.ropes.Aspect;
import net.rezmason.ropes.Types;
import net.rezmason.ropes.GridNode;
import net.rezmason.ropes.State;
import net.rezmason.ropes.StatePlan;
import net.rezmason.scourge.model.aspects.FreshnessAspect;
import net.rezmason.scourge.model.aspects.OwnershipAspect;

using Lambda;
using net.rezmason.ropes.GridUtils;
using net.rezmason.utils.Pointers;

class BoardUtils {

    private inline static var ALPHABET:Int = "a".charCodeAt(0);

    private static var ADD_SPACES:EReg = ~/([^\n\t])/g;

    public inline static function grabXY(state:State, east:Int, south:Int):BoardNode {
        return state.nodes[0].run(Gr.nw).run(Gr.w).run(Gr.n).run(Gr.s, south).run(Gr.e, east);
    }

    public static function spitBoard(state:State, plan:StatePlan, addSpaces:Bool = true, otherNodeAspects:Hash<String> = null):String {

        if (state.nodes.length == 0) return "empty grid";

        if (otherNodeAspects == null) otherNodeAspects = new Hash<String>();
        var otherAspectPtrs:Hash<AspectPtr> = new Hash<AspectPtr>();
        for (id in otherNodeAspects.keys()) otherAspectPtrs.set(id, plan.nodeAspectLookup.get(id));

        var str:String = "";

        var grid:BoardNode = state.nodes[0].run(Gr.nw).run(Gr.w).run(Gr.n);

        var occupier_:AspectPtr = plan.nodeAspectLookup.get(OwnershipAspect.OCCUPIER.id);
        var isFilled_:AspectPtr = plan.nodeAspectLookup.get(OwnershipAspect.IS_FILLED.id);

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
                        case (occupier != Aspect.NULL && isFilled == Aspect.FALSE): String.fromCharCode(ALPHABET + occupier);
                        case (occupier != Aspect.NULL): "" + occupier;
                        case (isFilled == Aspect.TRUE): "X";
                        case (isFilled == Aspect.FALSE && occupier == Aspect.NULL): " ";
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

        if (nodes.length > 0) {
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
