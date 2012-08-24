package net.rezmason.utils;

typedef Ptr<T> = #if USE_POINTERS {>Int,} #else Int #end ;

class Pointers {
    public inline static function dref<T>(p:Ptr<T>, a:Array<T>):T { return a[untyped p]; }
    public inline static function mod<T>(p:Ptr<T>, a:Array<T>, v:T):T { return a[untyped p] = v; }
    public inline static function ptr<T>(a:Array<T>, i:Int):Ptr<T> { return untyped i; }
    public inline static function pointerArithmetic(i:Int):Ptr<Dynamic> { return untyped i; }
}
