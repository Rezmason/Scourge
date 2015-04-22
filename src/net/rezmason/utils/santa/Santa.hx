package net.rezmason.utils.santa;

import haxe.ds.ObjectMap;

// Gave you presents. It was your parents the whole time.

enum InjectionType<T> {
    Instance(classToInstantiate:Class<T>, constructorArgs:Array<Dynamic>);
    Singleton(instance:T);
}

class Santa {

    static var classMap:ObjectMap<Dynamic, InjectionType<Dynamic>> = new ObjectMap();
    static var idClassMap:ObjectMap<Dynamic, Map<String, InjectionType<Dynamic>>> = new ObjectMap();

    public inline static function mapToClass<T>(clazz:Class<T>, present:InjectionType<T>):Bool {
        var replacing:Bool = classMap.exists(clazz);
        classMap.set(clazz, present);
        return replacing;
    }

    public inline static function mapToID<T>(clazz:Class<T>, id:String, present:InjectionType<T>):Bool {
        if (!idClassMap.exists(clazz)) idClassMap.set(clazz, new Map());
        var idMap = idClassMap.get(clazz);
        var replacing:Bool = idMap.exists(id);
        idMap.set(id, present);
        return replacing;
    }

    @:allow(net.rezmason.utils.santa)
    inline static function askFor<T>(clazz:Class<T>, ?id:String):T {
        var result:T = null;
        var type = null;
        if (id == null) type = classMap.get(clazz);
        else if (idClassMap.exists(clazz)) type = idClassMap.get(clazz).get(id);
        switch (type) {
            case null: throw 'Santa can\'t give you a ${clazz}';
            case Instance(classToInstantiate, args): result = Type.createInstance(classToInstantiate, args);
            case Singleton(instance): result = instance;
        }
        return result;
    }
}
