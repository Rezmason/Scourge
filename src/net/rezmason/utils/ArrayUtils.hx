package net.rezmason.utils;

using Lambda;

class ArrayUtils {

    public inline static function absorb<T>(a:Array<T>, b:Array<T>):Void {
        if (a == null) throw "You can't absorb into a null array.";
        if (b != null) for (item in b) if (!a.has(item)) a.push(item);
    }
}
