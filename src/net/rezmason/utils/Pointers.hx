package net.rezmason.utils;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#end

#if USE_POINTERS
    typedef Ptr<T> = {
        var _(default, null):Null<Int>;
        var t(default, null):Null<T>;
    }
    using Lambda;
#else
    typedef Ptr<T> = Int;
#end

class Pointers {

    #if USE_POINTERS
    public static var arrays:Array<Dynamic> = [];
    public static var locks:Array<Bool> = [];
    #end

    public #if !USE_POINTERS inline #end static function at<T>(a:Array<T>, p:Ptr<T>):T {
        #if USE_POINTERS
            if (p == null) throw "Null pointer";
            var index:Int = arrays.indexOf(a);
            //if (index == -1) throw "Array is not registered";
            return a[p._];
        #else return a[p];
        #end
    }

    public #if !USE_POINTERS inline #end static function d<T>(p:Ptr<T>, a:Array<T>):T {
        #if USE_POINTERS
            if (a == null) throw "Null array";
            var index:Int = arrays.indexOf(a);
            //if (index == -1) throw "Array is not registered";
            return a[p._];
        #else return a[p];
        #end
    }

    public #if !USE_POINTERS inline #end static function mod<T>(a:Array<T>, p:Ptr<T>, v:T):T {
        #if USE_POINTERS
            if (p == null) throw "Null pointer";
            var index:Int = arrays.indexOf(a);
            //if (index == -1) throw "Array is not registered";
            if (locks[index]) throw "Array is locked";
            return a[p._] = v;
        #else return a[p] = v;
        #end
    }

    public #if !USE_POINTERS inline #end static function ptr<T>(a:Array<T>, i:Int):Ptr<T> {
        #if USE_POINTERS
            var index:Int = arrays.indexOf(a);
            //if (index == -1) throw "Array is not registered";
            return {_:i, t:null};
        #else return i;
        #end
    }

    public #if !USE_POINTERS inline #end static function intToPointer<T>(i:Int):Ptr<T> {
        #if USE_POINTERS return {_:i, t:null};
        #else return i;
        #end
    }

    public #if !USE_POINTERS inline #end static function pointerToInt<T>(p:Ptr<T>):Int {
        #if USE_POINTERS return p._;
        #else return p;
        #end
    }

    public #if !USE_POINTERS inline #end static function register<T>(a:Array<T>):Bool {
        #if USE_POINTERS
            if (arrays.has(a)) return false;
            arrays.push(a);
            locks.push(false);
        #end
        return true;
    }

    public #if !USE_POINTERS inline #end static function lock<T>(a:Array<T>):Void {
        #if USE_POINTERS
            var index:Int = arrays.indexOf(a);
            //if (index == -1) throw "Array is not registered";
            locks[index] = true;
        #end
    }

    public #if !USE_POINTERS inline #end static function unlock<T>(a:Array<T>):Void {
        #if USE_POINTERS
            var index:Int = arrays.indexOf(a);
            //if (index == -1) throw "Array is not registered";
            locks[index] = false;
        #end
    }
}
