package net.rezmason.utils;

import haxe.ds.IntMap;

class IntMapUtils {

    public inline static function absorb<T>(a:IntMap<T>, b:IntMap<T>):Void {
        if (a == null) throw "You can't absorb into a null hash.";
        if (b != null)
        {
            for (key in b.keys()) a.set(key, b.get(key));
        }
    }
}
