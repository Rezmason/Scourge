package net.rezmason.utils;

using Lambda;

class MapUtils {

    public inline static function absorb<K, V>(a:Map<K, V>, b:Map<K, V>):Void {
        if (a == null) throw 'You can\'t absorb into a null map.';
        if (b != null) for (key in b.keys()) if (!a.exists(key)) a[key] = b[key];
    }
}
