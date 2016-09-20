package net.rezmason.gl.capabilities;

import haxe.ds.ObjectMap;

@:access(net.rezmason.gl.capabilities.Probe)
class Capabilities {
    static var probes:ObjectMap<Dynamic, Bool> = new ObjectMap();
    public static function isSupported(probeType:Class<Probe>) {
        if (!probes.exists(probeType)) probes.set(probeType, Type.createInstance(probeType, []).test());
        return probes.get(probeType);
    }
}
