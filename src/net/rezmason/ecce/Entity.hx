package net.rezmason.ecce;

import net.rezmason.utils.ClassName;

class Entity {
    var ecce:Ecce;
    var compsByType:Map<ClassName<Dynamic>, Dynamic> = new Map();
    @:allow(net.rezmason.ecce) var inUse:Bool = false;
    @:allow(net.rezmason.ecce) var bitfield:Bitfield = 0;
    @:allow(net.rezmason.ecce) inline function new(ecce) this.ecce = ecce;
    
    
    public inline function get<T>(type:Class<T>):T return cast compsByType.get(new ClassName(type));
    
    public inline function add(type:Class<Dynamic>) {
        var typeName = new ClassName(type);
        if (!compsByType.exists(typeName)) {
            compsByType.set(typeName, ecce.dispenseComponent(typeName));
            ecce.mutate(this, typeName, true);
        }
    }
    
    public inline function remove(type:Class<Dynamic>) {
        var typeName = new ClassName(type);
        if (compsByType.exists(typeName)) {
            ecce.collectComponent(typeName, compsByType.get(typeName));
            compsByType.remove(typeName);
            ecce.mutate(this, typeName, false);
        }
    }

    public inline function copyFrom(src:Entity) {
        for (typeName in compsByType.keys()) {
            var comp = compsByType.get(typeName);
            if (comp.copyFrom != null) comp.copyFrom(src.compsByType.get(typeName));
            else Ecce.copyComp(comp, src.compsByType.get(typeName));
        }
    }

    @:allow(net.rezmason.ecce)
    inline function destructor() {
        for (typeName in compsByType.keys()) {
            ecce.collectComponent(typeName, compsByType.get(typeName));
            compsByType.remove(typeName);
            ecce.mutate(this, typeName, false);
        }
    }
}
