package net.rezmason.gl;

import lime.graphics.opengl.GLTexture;

@:allow(net.rezmason.gl) 
class Texture extends Artifact {
    public var type(default, null):DataType;
    public var format(default, null):PixelFormat;
    var nativeTexture:GLTexture;
}
