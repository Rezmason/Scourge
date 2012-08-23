package net.rezmason.utils;

typedef Pointer<T> = #if USE_POINTERS {>Int,} #else Int #end ;

class Pointers {
    public inline static function d<T>(p:Pointer<T>, a:Array<T>):T { return a[untyped p]; }
    public inline static function ptr<T>(a:Array<T>, i:Int):Pointer<T> { return untyped i; }
}
