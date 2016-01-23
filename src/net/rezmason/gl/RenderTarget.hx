package net.rezmason.gl;

import lime.graphics.opengl.GLFramebuffer;

@:allow(net.rezmason.gl)
class RenderTarget extends Artifact {
    
    var _width:UInt = 0;
    var _height:UInt = 0;
    var frameBuffer:GLFramebuffer;
    
    public var width(get, null):UInt;
    public var height(get, null):UInt;
    
    inline function get_width() return _width;
    inline function get_height() return _height;
    
    function new() {}
}
