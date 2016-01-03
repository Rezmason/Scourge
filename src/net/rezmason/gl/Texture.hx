package net.rezmason.gl;

import net.rezmason.gl.GLTypes;
import net.rezmason.gl.TextureFormat;

@:allow(net.rezmason.gl) 
class Texture extends Artifact {
    public var format(default, null):TextureFormat;
    var nativeTexture:NativeTexture;
}
