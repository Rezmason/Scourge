package net.rezmason.utils.santa;

// Gave you presents. It was your parents the whole time.

enum InjectionType<T> {
    Instance(inst:Void->T);
    Singleton(instance:T);
}

class Santa {

    static var classMap:Map<String, InjectionType<Dynamic>> = new Map();
    static var idClassMap:Map<String, Map<String, InjectionType<Dynamic>>> = new Map();

    public inline static function mapToClass<T>(clazz:Class<T>, present:InjectionType<T>):Bool {
        var className = new ClassName(clazz);
        var replacing:Bool = classMap.exists(className);
        classMap.set(className, present);
        return replacing;
    }

    public inline static function mapToID<T>(clazz:Class<T>, id:String, present:InjectionType<T>):Bool {
        var className = new ClassName(clazz);
        if (!idClassMap.exists(className)) idClassMap.set(className, new Map());
        var idMap = idClassMap.get(className);
        var replacing:Bool = idMap.exists(id);
        idMap.set(id, present);
        return replacing;
    }

    @:allow(net.rezmason.utils.santa)
    inline static function askFor<T>(clazz:Class<T>, ?id:String):T {
        var className = new ClassName(clazz);
        var result:T = null;
        var type = null;
        if (id == null) type = classMap.get(className);
        else if (idClassMap.exists(className)) type = idClassMap.get(className).get(id);

        switch (type) {
            case null: throw 'Santa can\'t give you a ${clazz}';
            case Instance(inst): result = inst();
            case Singleton(instance): result = instance;
        }
        return result;
    }
}
