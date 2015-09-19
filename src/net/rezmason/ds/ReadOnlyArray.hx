package net.rezmason.ds;

@:forward(iterator, length, copy, map, filter, slice, join)
abstract ReadOnlyArray<T>(Array<T>) from Array<T> {
    @:arrayAccess inline function acc(i:UInt):T return this[i];
}
