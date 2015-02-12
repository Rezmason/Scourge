package net.rezmason.ropes.aspect;

import net.rezmason.ropes.aspect.Aspect.*;
import net.rezmason.ropes.RopesTypes;

using Lambda;
using net.rezmason.ropes.GridUtils;
using net.rezmason.utils.Pointers;

class AspectUtils {

    public inline static function iterate(me:AspectSet, list:Array<AspectSet>, itrPtr:AspectPtr):AspectSetIterator {
        return new AspectSetIterator(me, list, itrPtr);
    }

    public inline static function listToArray(me:AspectSet, list:Array<AspectSet>, itrPtr:AspectPtr):Array<AspectSet> {
        var arr:Array<AspectSet> = [];
        for (me in iterate(me, list, itrPtr)) arr.push(me);
        return arr;
    }

    public inline static function listToAssocArray(me:AspectSet, list:Array<AspectSet>, itrPtr:AspectPtr, keyPtr:AspectPtr):Array<AspectSet> {
        var arr:Array<AspectSet> = [];
        for (me in iterate(me, list, itrPtr)) arr[me[keyPtr]] = me;
        return arr;
    }

    public inline static function removeSet(me:AspectSet, list:Array<AspectSet>, next:AspectPtr, prev:AspectPtr):AspectSet {
        var nextSetID:Int = me[next];
        var prevSetID:Int = me[prev];

        var nextSet:AspectSet = null;

        var wasConnected:Bool = false;

        if (nextSetID != NULL) {
            wasConnected = true;
            nextSet = list[nextSetID];
            list[nextSetID][prev] = prevSetID;
        }

        if (prevSetID != NULL) {
            wasConnected = true;
            list[prevSetID][next] = nextSetID;
        }

        if (wasConnected) {
            me[next] = NULL;
            me[prev] = NULL;
        }

        return nextSet;
    }

    public inline static function addSet(you:AspectSet, me:AspectSet, list:Array<AspectSet>, id:AspectPtr, next:AspectPtr, prev:AspectPtr):AspectSet {
        removeSet(me, list, next, prev);

        var prevSetID:Int = you[prev];
        var myID:Int = me[id];

        me[next] = you[id];
        me[prev] = prevSetID;
        you[prev] = myID;
        if (prevSetID != NULL) {
            var prevSet:AspectSet = list[prevSetID];
            prevSet[next] = myID;
        }

        return me;
    }

    public inline static function chainByAspect(list:Array<AspectSet>, id:AspectPtr, next:AspectPtr, prev:AspectPtr):Void {

        list = list.copy();
        while (list.remove(null)) {}

        if (list.length > 0) {

            var me:AspectSet = list[0];

            for (ike in 1...list.length) {
                var nextSet:AspectSet = list[ike];
                me[next] = nextSet[id];
                nextSet[prev] = me[id];
                me = nextSet;
            }

            me[next] = NULL;
            me = list[0];
            me[prev] = NULL;
        }
    }
}

class AspectSetIterator {

    private var me:AspectSet;
    private var list:Array<AspectSet>;
    private var aspectPointer:AspectPtr;

    public function new(_me:AspectSet, _list:Array<AspectSet>, _itrPtr:AspectPtr):Void {
        me = _me;
        list = _list;
        aspectPointer = _itrPtr;
    }

    public function hasNext():Bool {
        return me != null;
    }

    public function next():AspectSet {
        var lastSet:AspectSet = me;
        var meIndex:Int = me[aspectPointer];
        if (meIndex == NULL) me = null;
        else me = list[meIndex];
        return lastSet;
    }
}
