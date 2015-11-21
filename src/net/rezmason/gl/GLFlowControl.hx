package net.rezmason.gl;

typedef GLFlowControl = {
    var onConnect:Void->Void;
    var onDisconnect:Void->Void;

    var connect(default, null):Void->Void;
    var disconnect(default, null):Void->Void;
    var relinquish(default, null):Void->Void;
}
