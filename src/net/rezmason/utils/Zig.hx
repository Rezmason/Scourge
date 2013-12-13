package net.rezmason.utils;

// You know what you doing.

class Zig<T> {

    var subs:Array<T>;

    public var dispatch(default, null):T;

    public function new() {
        subs = [];
        dispatch = Reflect.makeVarArgs(function(args) for (sub in subs) Reflect.callMethod(null, sub, args));
    }

    public function add(sub) if (!Lambda.has(subs, sub)) subs.push(sub);
    public function remove(sub) if (Lambda.has(subs, sub)) subs.splice(Lambda.indexOf(subs, sub), 1);
    public function removeAll() subs.splice(0, subs.length);
}
