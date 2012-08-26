package net.rezmason.utils;

typedef Ptr<T> = #if USE_POINTERS {_:Null<Int>,} #else Int #end ;

class Pointers {

    public inline static function dref<T>(p:Ptr<T>, a:Array<T>):T {
        #if USE_POINTERS return a[p._];
        #else return a[p];
        #end
    }

    public inline static function mod<T>(p:Ptr<T>, a:Array<T>, v:T):T {
        #if USE_POINTERS return a[p._] = v;
        #else return a[p] = v;
        #end
    }

    public inline static function ptr<T>(a:Array<T>, i:Int):Ptr<T> {
        #if USE_POINTERS return {_:i};
        #else return i;
        #end
    }

    public inline static function pointerArithmetic<T>(i:Int):Ptr<T> {
        #if USE_POINTERS return {_:i};
        #else return i;
        #end
    }

    public inline static function isNull<T>(p:Ptr<T>):Bool {
        #if USE_POINTERS return p == null || p._ == null;
        #else return p == null;
        #end
    }
}
