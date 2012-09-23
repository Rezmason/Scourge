package net.rezmason.scourge.model;

import net.rezmason.scourge.model.ModelTypes;

using Lambda;
using net.rezmason.scourge.model.GridUtils;
using net.rezmason.utils.Pointers;

class AspectUtils {

    public inline static function iterate(me:AspectSet, list:Array<AspectSet>, _aspectPointer:AspectPtr):AspectSetIterator {
        return new AspectSetIterator(me, list, _aspectPointer);
    }

    public inline static function listToArray(me:AspectSet, list:Array<AspectSet>, _aspectPointer:AspectPtr):Array<AspectSet> {
        var arr:Array<AspectSet> = [];
        for (me in iterate(me, list, _aspectPointer)) arr.push(me);
        return arr;
    }

    public inline static function removeNode(me:AspectSet, list:Array<AspectSet>, next:AspectPtr, prev:AspectPtr):AspectSet {
        var nextNodeID:Int = me.at(next);
        var prevNodeID:Int = me.at(prev);

        var nextNode:AspectSet = null;

        var wasConnected:Bool = false;

        if (nextNodeID != Aspect.NULL) {
            wasConnected = true;
            nextNode = list[nextNodeID];
            list[nextNodeID].mod(prev, prevNodeID);
        }

        if (prevNodeID != Aspect.NULL) {
            wasConnected = true;
            list[prevNodeID].mod(next, nextNodeID);
        }

        if (wasConnected) {
            me.mod(next, Aspect.NULL);
            me.mod(prev, Aspect.NULL);
        }

        return nextNode;
    }

    public inline static function addNode(you:AspectSet, me:AspectSet, list:Array<AspectSet>, id:AspectPtr, next:AspectPtr, prev:AspectPtr):AspectSet {
        removeNode(me, list, next, prev);

        var prevNodeID:Int = you.at(prev);
        var myID:Int = me.at(id);

        me.mod(next, you.at(id));
        me.mod(prev, prevNodeID);
        you.mod(prev, myID);
        if (prevNodeID != Aspect.NULL) {
            var prevNode:AspectSet = list[prevNodeID];
            prevNode.mod(next, myID);
        }

        return me;
    }

    public inline static function chainByAspect(list:Array<AspectSet>, id:AspectPtr, next:AspectPtr, prev:AspectPtr):Void {
        list = list.copy();
        while (list.remove(null)) {}

        var me:AspectSet = list[0];

        for (ike in 1...list.length) {
            var nextNode:AspectSet = list[ike];
            me.mod(next, nextNode.at(id));
            nextNode.mod(prev, me.at(id));
            me = nextNode;
        }

        me.mod(next, Aspect.NULL);
        me = list[0];
        me.mod(prev, Aspect.NULL);
    }
}

class AspectSetIterator {

    private var me:AspectSet;
    private var list:Array<AspectSet>;
    private var aspectPointer:AspectPtr;

    public function new(_me:AspectSet, _list:Array<AspectSet>, _aspectPointer:AspectPtr):Void {
        me = _me;
        list = _list;
        aspectPointer = _aspectPointer;
    }

    public function hasNext():Bool {
        return me != null;
    }

    public function next():AspectSet {
        var lastNode:AspectSet = me;
        var meIndex:Int = me.at(aspectPointer);
        if (meIndex == Aspect.NULL) me = null;
        else me = list[meIndex];
        return lastNode;
    }
}
