package net.rezmason.utils;

class Errand<T:(Function)> {
    public var onComplete(default, null):Zig<T> = new Zig();
    public function run():Void throw 'Override';
}
