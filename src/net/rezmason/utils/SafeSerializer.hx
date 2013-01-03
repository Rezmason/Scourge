package net.rezmason.utils;

import haxe.Serializer;

class SafeSerializer {
    public static function run(obj:Dynamic):String {
        var useCache:Bool = Serializer.USE_CACHE;
        Serializer.USE_CACHE = true;
        var string:String = Serializer.run(obj);
        Serializer.USE_CACHE = useCache;
        return string;
    }
}
