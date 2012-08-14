package net.rezmason.utils;

class IntHashUtils {

    public inline static function absorb<T>(a:IntHash<T>, b:IntHash<T>):Void {
        for (key in b.keys()) a.set(key, b.get(key));
    }
}
