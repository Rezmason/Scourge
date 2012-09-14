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

    public static function freshen(state:State, east:Int, south:Int, value:Int = 1):Void {
        var node:BoardNode = state.nodes[0].run(Gr.nw).run(Gr.w).run(Gr.n).run(Gr.s, south).run(Gr.e, east);
        var freshness_:AspectPtr = state.nodeAspectLookup[FreshnessAspect.FRESHNESS.id];
        state.history.set(node.value.at(freshness_), value);
    }

    public static function spitBoard(state:State, addSpaces:Bool = true, otherNodeAspects:IntHash<String> = null):String {

        if (state.nodes.length == 0) return "empty grid";

        if (otherNodeAspects == null) otherNodeAspects = new IntHash<String>();
        var otherAspectPtrs:IntHash<AspectPtr> = new IntHash<AspectPtr>();
        for (id in otherNodeAspects.keys()) otherAspectPtrs.set(id, state.nodeAspectLookup[id]);

        var str:String = "";

        var grid:BoardNode = state.nodes[0].run(Gr.nw).run(Gr.w).run(Gr.n);

        var occupier_:AspectPtr = state.nodeAspectLookup[OwnershipAspect.OCCUPIER.id];
        var isFilled_:AspectPtr = state.nodeAspectLookup[OwnershipAspect.IS_FILLED.id];

        for (row in grid.walk(Gr.s)) {
            str += "\n";
            for (column in row.walk(Gr.e)) {

                var otherAspectFound:Bool = false;

                for (id in otherAspectPtrs.keys()) {
                    var ptr:AspectPtr = otherAspectPtrs.get(id);
                    if (state.history.get(column.value.at(ptr)) > 0) {
                        otherAspectFound = true;
                        str += otherNodeAspects.get(id);
                        break;
                    }
                }

                if (!otherAspectFound) {
                    var occupier:Int = state.history.get(column.value.at(occupier_));
                    var isFilled:Int = state.history.get(column.value.at(isFilled_));

                    str += switch (true) {
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

    public inline static function iterate(_node:BoardNode, _state:State, _aspectPointer:AspectPtr):BoardNodeIterator {
        return new BoardNodeIterator(_node, _state, _aspectPointer);
    }

    public inline static function boardListToArray(_node:BoardNode, _state:State, _aspectPointer:AspectPtr):Array<BoardNode> {
        var arr:Array<BoardNode> = [];
        for (node in iterate(_node, _state, _aspectPointer)) arr.push(node);
        return arr;
    }

    public inline static function removeNode(node:BoardNode, state:State, next:AspectPtr, prev:AspectPtr):BoardNode {
        var history:StateHistory = state.history;
        var nextNodeID:Int = history.get(node.value.at(next));
        var prevNodeID:Int = history.get(node.value.at(prev));

        var nextNode:BoardNode = null;

        var wasConnected:Bool = false;

        if (nextNodeID != Aspect.NULL) {
            wasConnected = true;
            nextNode = state.nodes[nextNodeID];
            history.set(state.nodes[nextNodeID].value.at(prev), prevNodeID);
        }

        if (prevNodeID != Aspect.NULL) {
            wasConnected = true;
            history.set(state.nodes[prevNodeID].value.at(next), nextNodeID);
        }

        if (wasConnected) {
            history.set(node.value.at(next), Aspect.NULL);
            history.set(node.value.at(prev), Aspect.NULL);
        }

        return nextNode;
    }

    public inline static function addNode(node:BoardNode, addedNode:BoardNode, state:State, next:AspectPtr, prev:AspectPtr):BoardNode {
        var history:StateHistory = state.history;

        removeNode(addedNode, state, next, prev);

        var prevNodeID:Int = history.get(node.value.at(prev));

        history.set(addedNode.value.at(next), node.id);
        history.set(addedNode.value.at(prev), prevNodeID);
        history.set(node.value.at(prev), addedNode.id);
        if (prevNodeID != Aspect.NULL) {
            var prevNode:BoardNode = state.nodes[prevNodeID];
            history.set(prevNode.value.at(next), addedNode.id);
        }

        return addedNode;
    }

    public inline static function chainByAspect(nodes:Array<BoardNode>, state:State, next:AspectPtr, prev:AspectPtr):Void {
        var history:StateHistory = state.history;

        nodes = nodes.copy();
        while (nodes.remove(null)) {}

        var node:BoardNode = nodes[0];

        for (ike in 1...nodes.length) {
            var nextNode:BoardNode = nodes[ike];
            history.set(node.value.at(next), nextNode.id);
            history.set(nextNode.value.at(prev), node.id);
            node = nextNode;
        }

        history.set(node.value.at(next), Aspect.NULL);
        node = nodes[0];
        history.set(node.value.at(prev), Aspect.NULL);
    }
}

class BoardNodeIterator {

    private var node:BoardNode;
    private var state:State;
    private var aspectPointer:AspectPtr;

    public function new(_node:BoardNode, _state:State, _aspectPointer:AspectPtr):Void {
        node = _node;
        state = _state;
        aspectPointer = _aspectPointer;
    }

    public function hasNext():Bool {
        return node != null;
    }

    public function next():BoardNode {
        var lastNode:BoardNode = node;
        var nodeIndex:Int = state.history.get(node.value.at(aspectPointer));
        if (nodeIndex == Aspect.NULL) node = null;
        else node = state.nodes[nodeIndex];
        return lastNode;
    }
}
