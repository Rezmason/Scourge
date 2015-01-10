package net.rezmason.ecce;

import haxe.ds.ObjectMap;

class Ecce {

    var maxBitfield:Int = 1;
    var entities:Map<Entity, Bool> = new Map();
    var numEntities:Int = 0;
    var entityPool:Array<Entity> = [];
    var typeBitfields:ObjectMap<Dynamic, Bitfield> = new ObjectMap();
    var queriesByBitfield:Map<Bitfield, Query> = new Map();
    var transitionsByBitfield:Map<Bitfield, Map<Bitfield, Array<Query>>> = new Map();
    var componentPools:ObjectMap<Dynamic, Array<Component>> = new ObjectMap();
    var componentBases:ObjectMap<Dynamic, Component> = new ObjectMap();

    public function new() query([]);

    public function dispense(types:Array<Class<Component>> = null) {
        var e = entityPool.pop();
        if (e == null) e = new Entity(this);
        e.inUse = true;
        entities[e] = true;
        numEntities++;
        if (types != null) for (type in types) e.add(type);
        return e;
    }

    public function collect(e:Entity) {
        if (e.inUse) {
            e.inUse = false;
            entities.remove(e);
            numEntities--;
            entityPool.push(e);
            for (type in e.comps.keys()) e.remove(type);
        }
    }

    public function clone(e1:Entity) {
        var e2 = dispense([for (type in e1.comps.keys()) type]);
        e2.copyFrom(e1);
        return e2;
    }

    public function get(types:Array<Class<Component>> = null) return getByBitfield(getBitfieldForTypes(types));

    public function query(types:Array<Class<Component>>) {
        var bitfield = getBitfieldForTypes(types);
        if (queriesByBitfield[bitfield] == null) {
            if (numEntities > 0) throw 'New queries cannot be made while there are entities dispensed.';
            var query = new Query(bitfield);
            for (e in getByBitfield(bitfield)) query.add(e);
            queriesByBitfield[bitfield] = query;
        }
        return queriesByBitfield[bitfield];
    }

    @:allow(net.rezmason.ecce) function mutate(e:Entity, type, add) {
        var bitfield = add ? e.bitfield | getBitfieldForType(type) : e.bitfield & ~getBitfieldForType(type);
        if (transitionsByBitfield[e.bitfield] == null) transitionsByBitfield[e.bitfield] = new Map();
        var transitions = transitionsByBitfield[e.bitfield][bitfield];
        if (transitions == null) {
            transitions = [];
            for (queryBitfield in queriesByBitfield.keys()) {
                var containsOld = queryBitfield & e.bitfield == queryBitfield;
                var containsNew = queryBitfield & bitfield   == queryBitfield;
                if (containsOld != add && containsNew == add) transitions.push(queriesByBitfield[queryBitfield]);
            }
            transitionsByBitfield[e.bitfield][bitfield] = transitions;
        }
        for (query in transitionsByBitfield[e.bitfield][bitfield]) {
            if (add) query.add(e);
            else query.remove(e);
        }
        e.bitfield = bitfield;
    }

    @:allow(net.rezmason.ecce) function dispenseComponent(type:Class<Component>) {
        initComponentPool(type);
        var comp = componentPools.get(type).pop();
        if (comp == null) comp = Type.createInstance(type, []);
        comp.copyFrom(componentBases.get(type));
        return comp;
    }

    @:allow(net.rezmason.ecce) function collectComponent(type:Class<Component>, comp:Component) {
        initComponentPool(type);
        componentPools.get(type).push(comp);
    }

    inline function initComponentPool(type:Class<Component>) {
        if (!componentPools.exists(type)) {
            componentPools.set(type, []);
            componentBases.set(type, Type.createInstance(type, []));
        }
    }
    
    inline function getByBitfield(bitfield:Bitfield) {
        var ret = [];
        for (e in entities.keys()) if (e.bitfield & bitfield == bitfield) ret.push(e);
        return ret;
    }
    
    inline function getBitfieldForTypes(types:Array<Class<Component>> = null) {
        var bitfield = 0;
        if (types != null) for (type in types) bitfield = bitfield | getBitfieldForType(type);
        return bitfield;
    }

    inline function getBitfieldForType(type) {
        if (!typeBitfields.exists(type)) typeBitfields.set(type, 1 << maxBitfield++);
        return typeBitfields.get(type);
    }
}