package net.rezmason.utils.santa;

abstract Present<T>(T) {
    public inline function new(clazz:Class<T>, ?id:String) this = Santa.askFor(clazz, id);
    @:to public inline function toT():T return this;
}
