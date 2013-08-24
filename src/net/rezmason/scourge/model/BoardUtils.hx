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

    private inline static function ALPHABET():Int { return 'a'.charCodeAt(0); }

    private static var ADD_SPACES:EReg = ~/([^\n\t])/g;

    public inline static function grabXY(state:State, east:Int, south:Int):BoardNode {
        return state.nodes[0].run(Gr.nw).run(Gr.w).run(Gr.n).run(Gr.s, south).run(Gr.e, east);
    }

    public static function spitBoard(state:State, plan:StatePlan, addSpaces:Bool = true, otherNodeAspects:Map<String, String> = null):String {

        if (state.nodes.length == 0) return 'empty grid';

        if (otherNodeAspects == null) otherNodeAspects = new Map();
        var otherAspectPtrs:Map<String, AspectPtr> = new Map();
        for (id in otherNodeAspects.keys()) otherAspectPtrs[id] = plan.nodeAspectLookup[id];

        var str:String = '';

        var grid:BoardNode = state.nodes[0].run(Gr.nw).run(Gr.w).run(Gr.n);

        var occupier_:AspectPtr = plan.nodeAspectLookup[OwnershipAspect.OCCUPIER.id];
        var isFilled_:AspectPtr = plan.nodeAspectLookup[OwnershipAspect.IS_FILLED.id];

        for (row in grid.walk(Gr.s)) {
            str += '\n';
            for (column in row.walk(Gr.e)) {

                var otherAspectFound:Bool = false;

                for (id in otherAspectPtrs.keys()) {
                    var ptr:AspectPtr = otherAspectPtrs[id];
                    if (column.value[ptr] > 0) {
                        otherAspectFound = true;
                        str += otherNodeAspects[id];
                        break;
                    }
                }

                if (!otherAspectFound) {
                    var occupier:Null<Int> = column.value[occupier_];
                    var isFilled:Null<Int> = column.value[isFilled_];

                    if (occupier == null) str += 'n';
                    else if (occupier != Aspect.NULL && isFilled == Aspect.FALSE) str += String.fromCharCode(ALPHABET() + occupier);
                    else if (occupier != Aspect.NULL) str += '' + occupier;
                    else if (isFilled == Aspect.TRUE) str += 'X';
                    else if (isFilled == Aspect.FALSE && occupier == Aspect.NULL) str += ' ';
                }
            }
        }

        if (addSpaces) str = ADD_SPACES.replace(str, '$1 ');

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
        var nextNodeID:Int = node.value[next];
        var prevNodeID:Int = node.value[prev];

        var nextNode:BoardNode = null;

        var wasConnected:Bool = false;

        if (nextNodeID != Aspect.NULL) {
            wasConnected = true;
            nextNode = nodes[nextNodeID];
            nodes[nextNodeID].value[prev] = prevNodeID;
        }

        if (prevNodeID != Aspect.NULL) {
            wasConnected = true;
            nodes[prevNodeID].value[next] = nextNodeID;
        }

        if (wasConnected) {
            node.value[next] = Aspect.NULL;
            node.value[prev] = Aspect.NULL;
        }

        return nextNode;
    }

    public inline static function addNode(node:BoardNode, addedNode:BoardNode, nodes:Array<BoardNode>, id:AspectPtr, next:AspectPtr, prev:AspectPtr):BoardNode {
        removeNode(addedNode, nodes, next, prev);

        var prevNodeID:Int = node.value[prev];
        var addedNodeID:Int = addedNode.value[id];

        addedNode.value[next] = node.value[id];
        addedNode.value[prev] = prevNodeID;
        node.value[prev] = addedNodeID;
        if (prevNodeID != Aspect.NULL) {
            var prevNode:BoardNode = nodes[prevNodeID];
            prevNode.value[next] = addedNodeID;
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
                node.value[next] = nextNode.value[id];
                nextNode.value[prev] = node.value[id];
                node = nextNode;
            }

            node.value[next] = Aspect.NULL;
            node = nodes[0];
            node.value[prev] = Aspect.NULL;
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
        var nodeIndex:Int = node.value[aspectPointer];
        if (nodeIndex == Aspect.NULL) node = null;
        else node = nodes[nodeIndex];
        return lastNode;
    }
}
