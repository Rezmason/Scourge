package net.rezmason.gl.capabilities;

import net.rezmason.utils.ClassName;

@:access(net.rezmason.gl.capabilities.Probe)
class Capabilities {
    static var probes:Map<String, Bool> = new Map();
    public static function isSupported(probeType:Class<Probe>) {
        var probeTypeName = new ClassName(probeType);
        if (!probes.exists(probeTypeName)) probes.set(probeTypeName, Type.createInstance(probeType, []).test());
        return probes.get(probeTypeName);
    }
}
