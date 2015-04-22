package net.rezmason.utils;

class Errand<T> {
    public var onComplete(default, null):Zig<T> = new Zig();
    public function run():Void throw 'Override';
}
