package net.rezmason.ecce;

import haxe.ds.ObjectMap;

@:allow(net.rezmason.ecce)
class Entity {
    var bitfield:Bitfield = 0;
    var ecce:Ecce;
    var comps:ObjectMap<Dynamic, Component> = new ObjectMap();
    inline function new(ecce) this.ecce = ecce;
    public inline function get(type:Class<Component>) return comps.get(type);
    
    public inline function add(type:Class<Component>) {
        ecce.mutate(this, type, true); 
        comps.set(type, Type.createInstance(type, []));
    }
    
    public inline function remove(type:Class<Component>) {
        ecce.mutate(this, type, false); 
        comps.remove(type);
    }

    public inline function copyFrom(src:Entity) {
        for (type in comps.keys()) comps.get(type).copyFrom(src.comps.get(type));
    }
}
