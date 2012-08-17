package net.rezmason.utils;

class IntHashUtils {

    public inline static function absorb<T>(a:IntHash<T>, b:IntHash<T>):Void {
        if (a == null) throw "You can't absorb into a null hash.";
        if (b != null)
        {
            for (key in b.keys()) a.set(key, b.get(key));
        }
    }
}
