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

    public inline static function removeSet(me:AspectSet, list:Array<AspectSet>, next:AspectPtr, prev:AspectPtr):AspectSet {
        var nextSetID:Int = me.at(next);
        var prevSetID:Int = me.at(prev);

        var nextSet:AspectSet = null;

        var wasConnected:Bool = false;

        if (nextSetID != Aspect.NULL) {
            wasConnected = true;
            nextSet = list[nextSetID];
            list[nextSetID].mod(prev, prevSetID);
        }

        if (prevSetID != Aspect.NULL) {
            wasConnected = true;
            list[prevSetID].mod(next, nextSetID);
        }

        if (wasConnected) {
            me.mod(next, Aspect.NULL);
            me.mod(prev, Aspect.NULL);
        }

        return nextSet;
    }

    public inline static function addSet(you:AspectSet, me:AspectSet, list:Array<AspectSet>, id:AspectPtr, next:AspectPtr, prev:AspectPtr):AspectSet {
        removeSet(me, list, next, prev);

        var prevSetID:Int = you.at(prev);
        var myID:Int = me.at(id);

        me.mod(next, you.at(id));
        me.mod(prev, prevSetID);
        you.mod(prev, myID);
        if (prevSetID != Aspect.NULL) {
            var prevSet:AspectSet = list[prevSetID];
            prevSet.mod(next, myID);
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
                me.mod(next, nextSet.at(id));
                nextSet.mod(prev, me.at(id));
                me = nextSet;
            }

            me.mod(next, Aspect.NULL);
            me = list[0];
            me.mod(prev, Aspect.NULL);
        }
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
        var lastSet:AspectSet = me;
        var meIndex:Int = me.at(aspectPointer);
        if (meIndex == Aspect.NULL) me = null;
        else me = list[meIndex];
        return lastSet;
    }
}
