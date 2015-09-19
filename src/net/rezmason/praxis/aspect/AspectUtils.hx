package net.rezmason.praxis.aspect;

import net.rezmason.ds.ReadOnlyArray;
import net.rezmason.praxis.aspect.Aspect.*;
import net.rezmason.praxis.PraxisTypes;

class AspectUtils {

    public inline static function iterate<T>(me:AspectPointable<T>, list:ReadOnlyArray<AspectPointable<T>>, itrPtr:AspectPointer<T>):AspectPointableIterator<T> {
        return new AspectPointableIterator(me, list, itrPtr);
    }

    public inline static function listToArray<T>(me:AspectPointable<T>, list:ReadOnlyArray<AspectPointable<T>>, itrPtr:AspectPointer<T>):Array<AspectPointable<T>> {
        var arr = [];
        for (me in iterate(me, list, itrPtr)) arr.push(me);
        return arr;
    }

    public inline static function removeSet<T>(me:AspectPointable<T>, list:ReadOnlyArray<AspectPointable<T>>, next:AspectWritePointer<T>, prev:AspectWritePointer<T>):AspectPointable<T> {
        var nextSetID = me[next];
        var prevSetID = me[prev];

        var nextSet = null;

        var wasConnected = false;

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

    public inline static function addSet<T>(you:AspectPointable<T>, me:AspectPointable<T>, list:ReadOnlyArray<AspectPointable<T>>, id:AspectPointer<T>, next:AspectWritePointer<T>, prev:AspectWritePointer<T>):AspectPointable<T> {
        removeSet(me, list, next, prev);
        var prevSetID = you[prev];
        var myID = me[id];
        me[next] = you[id];
        me[prev] = prevSetID;
        you[prev] = myID;
        if (prevSetID != NULL) list[prevSetID][next] = myID;
        return me;
    }

    public inline static function chainByAspect<T>(list:ReadOnlyArray<AspectPointable<T>>, id:AspectPointer<T>, next:AspectWritePointer<T>, prev:AspectWritePointer<T>):Void {
        if (list.length > 0) {
            var me = list[0];

            for (ike in 1...list.length) {
                var nextSet = list[ike];
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

class AspectPointableIterator<T> {

    private var me:AspectPointable<T>;
    private var list:ReadOnlyArray<AspectPointable<T>>;
    private var aspectPointer:AspectPointer<T>;

    public function new(_me:AspectPointable<T>, _list:ReadOnlyArray<AspectPointable<T>>, _itrPtr:AspectPointer<T>):Void {
        me = _me;
        list = _list;
        aspectPointer = _itrPtr;
    }

    public function hasNext() return me != null;

    public function next():AspectPointable<T> {
        var lastSet:AspectPointable<T> = me;
        var meIndex = me[aspectPointer];
        if (meIndex == NULL) me = null;
        else me = list[meIndex];
        return lastSet;
    }
}
