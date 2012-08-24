package net.rezmason.utils;

typedef Ptr<T> = #if USE_POINTERS {>Int,} #else Int #end ;

class Pointers {
    public inline static function d<T>(p:Ptr<T>, a:Array<T>):T { return a[untyped p]; }
    public inline static function ptr<T>(a:Array<T>, i:Int):Ptr<T> { return untyped i; }
}
