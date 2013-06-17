package net.rezmason.utils;

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

abstract PtrArray<T>(Array<T>) {

    public inline function new(a:Array<T> = null) this = (a == null) ? [] : a.copy();
    public inline function wipe():Void this.splice(0, this.length);
    public inline function copy():PtrArray<T> return cast this.copy();
    public inline function copyTo(dest:PtrArray<T>, offset:Int = 0):Void for (ike in 0...this.length) dest[ike + offset] = this[ike];
    public inline function map<U>(mapFunc:T->U):PtrArray<U> return cast this.map(mapFunc);
    public inline function mapTo<U>(mapFunc:T->U, dest:PtrArray<U>, offset:Int = 0):Void for (ike in 0...this.length) dest[ike + offset] = mapFunc(this[ike]);
    inline function push(val:T):Void this.push(val);
    @:arrayAccess inline function arrayAccess(index:Int):T return this[index];
    @:arrayAccess inline function arrayWrite<T>(index:Int, value:T):T return this[index] = value;
    public inline function size():Int return this.length;

    public inline function at(p:Ptr<T>):T {
        #if USE_POINTERS if (p == null) throw 'Null pointer'; return this[p._];
        #else return this[p];
        #end
    }

    public inline function mod(p:Ptr<T>, v:T):T {
        #if USE_POINTERS
            if (p == null) throw 'Null pointer';
            if (Pointers.isLocked(p)) throw 'Pointer is locked';
            return this[p._] = v;
        #else return this[p] = v;
        #end
    }

    public inline function ptr(i:Int, pSet:PtrSet):Ptr<T> {
        #if USE_POINTERS return {_:i, t:null, pSet:pSet._};
        #else return i;
        #end
    }
}

class Pointers {

    static var ids:Int = 0;

    #if USE_POINTERS
    public static var locks:Array<Bool> = [];
    #end

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
    public static function isLocked<T>(p:Ptr<T>):Bool {
        #if USE_POINTERS return locks[p.pSet];
        #else return false;
        #end
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
