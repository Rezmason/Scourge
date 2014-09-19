package net.rezmason.gl;

import net.rezmason.gl.GLTypes;

@:allow(net.rezmason.gl.GLSystem)
class Artifact {

    var context:Context;

    function connectToContext(context:Context):Void this.context = context;
    function disconnectFromContext():Void context = null;
    function isConnectedToContext():Bool return this.context != null;
}