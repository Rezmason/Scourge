package net.rezmason.gl;

import lime.graphics.opengl.GLTexture;

@:allow(net.rezmason.gl) 
class Texture extends Artifact {
    public var dataType(default, null):DataType;
    public var pixelFormat(default, null):PixelFormat;
    public var dataFormat(default, null):DataFormat;
    var nativeTexture:GLTexture;
}
