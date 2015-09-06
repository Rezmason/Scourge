package net.rezmason.utils.pointers;

@:allow(net.rezmason.utils.pointers) 
abstract Pointer<T,U>(Int) to Int { inline function new(i) this = i; }

@:allow(net.rezmason.utils.pointers) 
abstract WritePointer<T,U>(Pointer<T,U>) to Pointer<T,U> { inline function new(i) this = new Pointer(i); }

abstract Pointable<T,U>(Array<T>) {
    public inline function new(a:Array<T> = null) this = (a == null) ? [] : a.copy();
    public inline function copy():Pointable<T,U> return new Pointable(this);
    public inline function copyTo(dest:Pointable<T,U>) {
        for (ike in 0...size()) dest.write(ike, this[ike]);
    }
    inline function write(index:Int, value:T):T return this[index] = value;
    public inline function map<Z>(mapFunc:T->Z):Pointable<Z,U> return new Pointable(this.map(mapFunc));
    public inline function size() return this.length;
    @:arrayAccess #if !cpp inline #end function ptrAccess(p:Pointer<T,U>):T return this[p];
    @:arrayAccess inline function ptrWrite(p:WritePointer<T,U>, v:T):T return this[p] = v;
    public inline function ptrs(pItr:PointerIterator<T,U> = null):PointerIterator<T,U> {
        if (pItr == null) pItr = new PointerIterator();
        pItr.init(this.length);
        return pItr;
    }
}

@:allow(net.rezmason.utils.pointers)
class PointerIterator<T,U> {
    var itr:Iterator<Int>;
    public inline function new():Void itr = 0...0;
    inline function init(l) itr = 0...l;
    public inline function hasNext() return itr.hasNext();
    public inline function next() return new WritePointer(itr.next());
}

abstract PointerSource<T,U>(Array<WritePointer<T,U>>) {
    public inline function new() this = [];
    public inline function add() {
        var ptr = new WritePointer(this.length);
        this.push(ptr);
        return ptr;
    }
    public inline function count() return this.length;
}
