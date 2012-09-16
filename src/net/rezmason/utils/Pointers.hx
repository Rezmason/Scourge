package net.rezmason.utils;

#if USE_POINTERS
    typedef Ptr<T> = {
        var _(default, null):Null<Int>;
        var t(default, null):Null<T>;
    }
#else
    typedef Ptr<T> = Int;
#end

class Pointers {

    public inline static function at<T>(a:Array<T>, p:Ptr<T>):T {
        #if USE_POINTERS if (p == null) throw "Null pointer"; return a[p._];
        #else return a[p];
        #end
    }

    public inline static function d<T>(p:Ptr<T>, a:Array<T>):T {
        #if USE_POINTERS if (p == null) throw "Null pointer"; return a[p._];
        #else return a[p];
        #end
    }

    public inline static function mod<T>(a:Array<T>, p:Ptr<T>, v:T):T {
        #if USE_POINTERS if (p == null) throw "Null pointer"; return a[p._] = v;
        #else return a[p] = v;
        #end
    }

    public inline static function ptr<T>(a:Array<T>, i:Int):Ptr<T> {
        #if USE_POINTERS return {_:i, t:null};
        #else return i;
        #end
    }

    public inline static function pointerArithmetic<T>(i:Int):Ptr<T> {
        #if USE_POINTERS return {_:i, t:null};
        #else return i;
        #end
    }
}
