package net.rezmason.utils.pointers;

@:allow(net.rezmason.utils.pointers)
abstract Ptr<T>(Int) to Int {
    inline function new(i) this = i;
}

@:allow(net.rezmason.utils.pointers)
abstract WritePtr<T>(Ptr<T>) to Ptr<T> {
    inline function new(i) this = new Ptr(i);
}

abstract Pointable<T>(Array<T>) {
    public inline function new(a:Array<T> = null) this = (a == null) ? [] : a.copy();
    public inline function copy():Pointable<T> return new Pointable(this);
    public inline function map<U>(mapFunc:T->U):Pointable<U> return new Pointable(this.map(mapFunc));
    public inline function size() return this.length;

    @:arrayAccess #if !cpp inline #end function ptrAccess(p:Ptr<T>):T return this[p];
    @:arrayAccess inline function ptrWrite(p:WritePtr<T>, v:T):T return this[p] = v;

    public inline function ptrs(pItr:PtrIterator<T> = null):PtrIterator<T> {
        if (pItr == null) pItr = new PtrIterator();
        pItr.init(this.length);
        return pItr;
    }
}

@:allow(net.rezmason.utils.pointers)
class PtrIterator<T> {
    var itr:Iterator<Int>;
    public inline function new():Void itr = 0...0;
    inline function init(l) itr = 0...l;
    public inline function hasNext() return itr.hasNext();
    public inline function next() return new WritePtr(itr.next());
}

abstract PointerSource<T>(Array<WritePtr<T>>) {
    public inline function new() this = [];
    public inline function add() {
        var ptr = new WritePtr<T>(this.length);
        this.push(ptr);
        return ptr;
    }
    public inline function count() return this.length;
}
