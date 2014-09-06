package net.rezmason.utils.santa;

abstract Present<T>(T) {
    public inline function new(clazz:Class<T>) this = Santa.askFor(clazz);
    @:to public inline function toT():T return this;
}
