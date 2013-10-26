package net.rezmason.scourge.model;

import net.rezmason.ropes.Aspect;
import net.rezmason.ropes.Types;
import net.rezmason.ropes.GridLocus;
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

    public inline static function grabXY(state:State, east:Int, south:Int):BoardLocus {
        return state.nodes[0].run(Gr.nw).run(Gr.w).run(Gr.n).run(Gr.s, south).run(Gr.e, east);
    }

    public static function spitBoard(state:State, plan:StatePlan, addSpaces:Bool = true, otherNodeAspects:Map<String, String> = null):String {
        if (state.nodes.length == 0) return 'empty grid';

        if (otherNodeAspects == null) otherNodeAspects = new Map();
        var otherAspectPtrs:Map<String, AspectPtr> = new Map();
        for (id in otherNodeAspects.keys()) otherAspectPtrs[id] = plan.nodeAspectLookup[id];

        var str:String = '';

        var grid:BoardLocus = state.nodes[0].run(Gr.nw).run(Gr.w).run(Gr.n);

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

    public inline static function iterate(_node:BoardLocus, _nodes:Array<BoardLocus>, _itrPtr:AspectPtr):BoardLocusIterator {
        return new BoardLocusIterator(_node, _nodes, _itrPtr);
    }

    public inline static function boardListToArray(_node:BoardLocus, _nodes:Array<BoardLocus>, _itrPtr:AspectPtr):Array<BoardLocus> {
        var arr:Array<BoardLocus> = [];
        for (node in iterate(_node, _nodes, _itrPtr)) arr.push(node);
        return arr;
    }

    public inline static function boardListToMap(_node:BoardLocus, _nodes:Array<BoardLocus>, _itrPtr:AspectPtr, _keyPtr:AspectPtr):Map<Int, BoardLocus> {
        var map:Map<Int, BoardLocus> = new Map();
        for (node in iterate(_node, _nodes, _itrPtr)) map[node.value[_keyPtr]] = node;
        return map;
    }

    public inline static function removeNode(node:BoardLocus, nodes:Array<BoardLocus>, next:AspectPtr, prev:AspectPtr):BoardLocus {
        var nextNodeID:Int = node.value[next];
        var prevNodeID:Int = node.value[prev];

        var nextNode:BoardLocus = null;

        if (nextNodeID != Aspect.NULL) {
            node.value[next] = Aspect.NULL;
            nextNode = nodes[nextNodeID];
            nodes[nextNodeID].value[prev] = prevNodeID;
        }

        if (prevNodeID != Aspect.NULL) {
            node.value[prev] = Aspect.NULL;
            nodes[prevNodeID].value[next] = nextNodeID;
        }

        return nextNode;
    }

    public inline static function addNode(node:BoardLocus, addedNode:BoardLocus, nodes:Array<BoardLocus>, id:AspectPtr, next:AspectPtr, prev:AspectPtr):BoardLocus {
        var prevNodeID:Int = node.value[prev];
        var addedNodeID:Int = addedNode.value[id];

        addedNode.value[next] = node.value[id];
        addedNode.value[prev] = prevNodeID;
        node.value[prev] = addedNodeID;
        if (prevNodeID != Aspect.NULL) {
            var prevNode:BoardLocus = nodes[prevNodeID];
            prevNode.value[next] = addedNodeID;
        }

        return addedNode;
    }

    public inline static function chainByAspect(nodes:Array<BoardLocus>, id:AspectPtr, next:AspectPtr, prev:AspectPtr):Void {
        nodes = nodes.copy();
        while (nodes.remove(null)) {}

        if (nodes.length > 0) {
            var node:BoardLocus = nodes[0];

            node.value[prev] = Aspect.NULL;

            for (ike in 1...nodes.length) {
                var nextNode:BoardLocus = nodes[ike];
                node.value[next] = nextNode.value[id];
                nextNode.value[prev] = node.value[id];
                node = nextNode;
            }

            node.value[next] = Aspect.NULL;
        }
    }
}

class BoardLocusIterator {

    private var node:BoardLocus;
    private var nodes:Array<BoardLocus>;
    private var itrPtr:AspectPtr;

    public function new(_node:BoardLocus, _nodes:Array<BoardLocus>, _itrPtr:AspectPtr):Void {
        node = _node;
        nodes = _nodes;
        itrPtr = _itrPtr;
    }

    public function hasNext():Bool {
        return node != null;
    }

    public function next():BoardLocus {
        var lastNode:BoardLocus = node;
        var nodeIndex:Int = node.value[itrPtr];
        if (nodeIndex == Aspect.NULL) node = null;
        else node = nodes[nodeIndex];
        return lastNode;
    }
}
