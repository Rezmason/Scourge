package net.rezmason.gl;

import net.rezmason.gl.GLTypes;

@:allow(net.rezmason.gl.GLSystem)
class Artifact {

    var context:Context;
    public var isDisposed(default, null):Bool;
    function new():Void isDisposed = false;
    function connectToContext(context:Context):Void this.context = context;
    function disconnectFromContext():Void context = null;
    public function isConnectedToContext():Bool return context != null;
    public function dispose():Void isDisposed = true;
}
