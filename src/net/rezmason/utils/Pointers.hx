package net.rezmason.utils;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#end

#if USE_POINTERS
    typedef Ptr<T> = {
        var _(default, null):Null<Int>;
        var t(default, null):Null<T>;
        var pSet(default, null):Int;
    }
#else
    typedef Ptr<T> = Int;
#end

typedef PtrSet = { var _(default, null):Int; }

class Pointers {

    static var ids:Int = 0;

    #if USE_POINTERS
    public static var locks:Array<Bool> = [];
    #end

    #if !USE_POINTERS inline #end
    public static function at<T>(a:Array<T>, p:Ptr<T>):T {
        #if USE_POINTERS if (p == null) throw "Null pointer"; return a[p._];
        #else return a[p];
        #end
    }

    #if !USE_POINTERS inline #end
    public static function d<T>(p:Ptr<T>, a:Array<T>):T {
        #if USE_POINTERS if (a == null) throw "Null array"; return a[p._];
        #else return a[p];
        #end
    }

    #if !USE_POINTERS inline #end
    public static function mod<T>(a:Array<T>, p:Ptr<T>, v:T):T {
        #if USE_POINTERS
            if (p == null) throw "Null pointer";
            if (locks[p.pSet]) throw "Pointer is locked";
            return a[p._] = v;
        #else return a[p] = v;
        #end
    }

    #if !USE_POINTERS inline #end
    public static function ptr<T>(a:Array<T>, i:Int, pSet:PtrSet):Ptr<T> {
        #if USE_POINTERS return {_:i, t:null, pSet:pSet._};
        #else return i;
        #end
    }

    #if !USE_POINTERS inline #end
    public static function intToPointer<T>(i:Int, pSet:PtrSet):Ptr<T> {
        #if USE_POINTERS return {_:i, t:null, pSet:pSet._};
        #else return i;
        #end
    }

    #if !USE_POINTERS inline #end
    public static function pointerToInt<T>(p:Ptr<T>):Int {
        #if USE_POINTERS return p._;
        #else return p;
        #end
    }

    #if !USE_POINTERS inline #end
    public static function makeSet():PtrSet {
        return {_:ids++};
    }

    #if !USE_POINTERS inline #end
    public static function lock(pSet:PtrSet):Void {
        #if USE_POINTERS locks[pSet._] = true; #end
    }

    #if !USE_POINTERS inline #end
    public static function unlock(pSet:PtrSet):Void {
        #if USE_POINTERS locks[pSet._] = false; #end
    }
}
