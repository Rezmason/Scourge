package net.rezmason.ecce;

@:allow(net.rezmason.ecce)
abstract Query(Map<Entity, Bool>) {
    inline function new(bitfield) this = new Map();
    public inline function iterator() return this.keys();
    inline function add(e) this[e] = true;
    inline function remove(e) this.remove(e);
}
