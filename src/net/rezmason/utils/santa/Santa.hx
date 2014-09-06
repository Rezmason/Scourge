package net.rezmason.utils.santa;

import haxe.ds.ObjectMap;

// Gave you presents. It was your parents the whole time.

enum InjectionType<T> {
    Instance(classToInstantiate:Class<T>, constructorArgs:Array<Dynamic>);
    Singleton(instance:T);
}

class Santa {

    static var classMap:ObjectMap<Dynamic, InjectionType<Dynamic>> = new ObjectMap();

    public inline static function mapToClass<T>(clazz:Class<T>, present:InjectionType<T>):Bool {
        var replacing:Bool = classMap.exists(clazz);
        classMap.set(clazz, present);
        return replacing;
    }

    @:allow(net.rezmason.utils.santa)
    inline static function askFor<T>(clazz:Class<T>):T {
        var result:T = null;
        switch (classMap.get(clazz)) {
            case null: throw 'Santa can\'t give you a ${clazz}';
            case Instance(classToInstantiate, args): result = Type.createInstance(classToInstantiate, args);
            case Singleton(instance): result = instance;
        }
        return result;
    }
}
