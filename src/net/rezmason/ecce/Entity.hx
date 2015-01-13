package net.rezmason.ecce;

import haxe.ds.ObjectMap;

@:allow(net.rezmason.ecce)
class Entity {
    var inUse:Bool = false;
    var bitfield:Bitfield = 0;
    var ecce:Ecce;
    var comps:ObjectMap<Dynamic, Component> = new ObjectMap();
    inline function new(ecce) this.ecce = ecce;
    public inline function get<T:(Component)>(type:Class<T>):T return cast comps.get(type);
    
    public inline function add(type:Class<Component>) {
        if (!comps.exists(type)) {
            comps.set(type, ecce.dispenseComponent(type));
            ecce.mutate(this, type, true);
        }
    }
    
    public inline function remove(type:Class<Component>) {
        if (comps.exists(type)) {
            ecce.collectComponent(type, comps.get(type));
            comps.remove(type);
            ecce.mutate(this, type, false);
        }
    }

    public inline function copyFrom(src:Entity) {
        for (type in comps.keys()) comps.get(type).copyFrom(src.comps.get(type));
    }
}
