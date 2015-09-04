package net.rezmason.utils.pointers;

abstract Ptr<T>(Int) {
    @:allow(net.rezmason.utils.pointers) inline function new(i) this = i;
    public inline static function intToPointer<T>(i) return new Ptr(i);
    @:to public inline function toInt() return this;
}

abstract PtrSet<T>(Array<T>) {

    public inline function new(a:Array<T> = null) this = (a == null) ? [] : a.copy();
    public inline function wipe():Void this.splice(0, this.length);
    public inline function copy():PtrSet<T> return new PtrSet(this);
    public inline function copyTo(dest:PtrSet<T>, offset:Int = 0):Void {
        for (ike in 0...this.length) dest.write(ike + offset, this[ike]);
    }
    public inline function map<U>(mapFunc:T->U):PtrSet<U> return new PtrSet(this.map(mapFunc));
    public inline function mapTo<U>(mapFunc:T->U, dest:PtrSet<U>, offset:Int):Void {
        for (ike in 0...this.length) dest.write(ike + offset, mapFunc(this[ike]));
    }

    inline function write(index:Int, value:T):T return this[index] = value;

    @:arrayAccess #if !cpp inline #end function ptrAccess(p:Ptr<T>):T { // Was inline; caused openFL issue
        return this[p.toInt()];
    }

    @:arrayAccess inline function ptrWrite(p:Ptr<T>, v:T):T {
        return this[p.toInt()] = v;
    }

    @:allow(net.rezmason.utils.PtrIterator) public inline function size():Int return this.length;

    public inline function ptr(i:Int):Ptr<T> return new Ptr(i);
    public inline function ptrs(pItr:PtrIterator<T> = null):PtrIterator<T> {
        if (pItr == null) pItr = new PtrIterator();
        pItr.attach(new PtrSet(this));
        return pItr;
    }
}

class PtrIterator<T> {

    var a:PtrSet<T>;
    var itr:Iterator<Int>;

    public function new():Void {}

    @:allow(net.rezmason.utils.pointers)
    function attach(a:PtrSet<T>):Void {
        this.a = a;
        itr = 0...a.size();
    }

    public inline function hasNext():Bool return itr.hasNext();
    public inline function next():Ptr<T> return a.ptr(itr.next());

}
