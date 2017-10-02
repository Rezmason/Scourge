package net.rezmason.ecce;

import net.rezmason.utils.ClassName;

class Ecce {

    var maxBitfield:Int = 1;
    var entities:Map<Entity, Bool> = new Map();
    var numEntities:Int = 0;
    var entityPool:Array<Entity> = [];
    var typeBitfields:Map<ClassName<Dynamic>, Bitfield> = new Map();
    var queriesByBitfield:Map<Bitfield, Query> = new Map();
    var transitionsByBitfield:Map<Bitfield, Map<Bitfield, Array<Query>>> = new Map();
    var componentPools:Map<ClassName<Dynamic>, Array<Dynamic>> = new Map();
    var componentBases:Map<ClassName<Dynamic>, Dynamic> = new Map();
    var typesByTypeName:Map<ClassName<Dynamic>, Class<Dynamic>> = new Map();

    public function new() query([]);

    public function dispense(types:Array<Class<Dynamic>> = null) {
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
            e.destructor();
        }
    }

    public function get(types:Array<Class<Dynamic>> = null) {
        if (types == null) types = [];
        return getByBitfield(getBitfieldForTypeNames([for (type  in types) new ClassName(type)]));
    }

    public function query(types:Array<Class<Dynamic>>) {
        var typeNames = [];
        for (type in types) {
            var typeName = new ClassName(type);
            typeNames.push(typeName);
            if (!typesByTypeName.exists(typeName)) {
                typesByTypeName.set(typeName, type);
            }
        }
        var bitfield = getBitfieldForTypeNames(typeNames);
        if (queriesByBitfield[bitfield] == null) {
            if (numEntities > 0) throw 'New queries cannot be made while there are entities dispensed.';
            var query = new Query(bitfield);
            for (e in getByBitfield(bitfield)) query.add(e);
            queriesByBitfield[bitfield] = query;
        }
        return queriesByBitfield[bitfield];
    }

    @:allow(net.rezmason.ecce) function mutate(e:Entity, type, add) {
        var bitfield = add ? e.bitfield | getBitfieldForTypeName(type) : e.bitfield & ~getBitfieldForTypeName(type);
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

    @:allow(net.rezmason.ecce) function dispenseComponent(typeName:ClassName<Dynamic>) {
        initComponentPool(typeName);
        var comp = componentPools.get(typeName).pop();
        if (comp == null) comp = Type.createInstance(typesByTypeName.get(typeName), []);
        else copyComp(comp, componentBases.get(typeName));
        return comp;
    }

    @:allow(net.rezmason.ecce) function collectComponent<T>(typeName:ClassName<T>, comp:T) {
        initComponentPool(typeName);
        componentPools.get(typeName).push(comp);
    }

    inline function initComponentPool(typeName:ClassName<Dynamic>) {
        if (!componentPools.exists(typeName)) {
            componentPools.set(typeName, []);
            componentBases.set(typeName, Type.createInstance(typesByTypeName.get(typeName), []));
        }
    }
    
    inline function getByBitfield(bitfield:Bitfield) {
        var ret = [];
        for (e in entities.keys()) if (e.bitfield & bitfield == bitfield) ret.push(e);
        return ret;
    }
    
    inline function getBitfieldForTypeNames(typeNames:Array<ClassName<Dynamic>> = null) {
        var bitfield = 0;
        if (typeNames != null) for (typeName in typeNames) bitfield = bitfield | getBitfieldForTypeName(typeName);
        return bitfield;
    }

    inline function getBitfieldForTypeName(typeName) {
        if (!typeBitfields.exists(typeName)) typeBitfields.set(typeName, 1 << maxBitfield++);
        return typeBitfields.get(typeName);
    }

    @:allow(net.rezmason.ecce) inline static function copyComp(to:Dynamic, from:Dynamic) {
        if (to != null && from != null) {
            for (field in Reflect.fields(to)) Reflect.setField(to, field, Reflect.field(from, field));
        }
    }
}
