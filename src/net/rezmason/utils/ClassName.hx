package net.rezmason.utils;

abstract ClassName<T>(String) to String {
    public inline function new(clazz:Class<T>) this = Type.getClassName(clazz);
}
