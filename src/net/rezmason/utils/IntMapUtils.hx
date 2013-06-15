package net.rezmason.utils;

 {
class IntMapUtils {

    public inline static function absorb<T>(a:Map<Int, T>, b:Map<Int, T>):Void {
        if (a == null) throw "You can't absorb into a null map.";
        if (b != null) for (key in b.keys()) a[key] = b[key];
    }
}
