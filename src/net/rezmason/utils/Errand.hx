package net.rezmason.utils;

import haxe.Constraints.Function;

class Errand<T:(Function)> {
    public var onComplete(default, null):Zig<T> = new Zig();
    public function run():Void throw 'Override';
}
