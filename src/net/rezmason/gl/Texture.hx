package net.rezmason.gl;

import lime.graphics.opengl.GLTexture;

@:allow(net.rezmason.gl) 
class Texture extends Artifact {
    public var format(default, null):TextureFormat;
    var nativeTexture:GLTexture;
}
