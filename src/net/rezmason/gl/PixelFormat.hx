package net.rezmason.gl;

import lime.graphics.opengl.GL;
@:enum abstract PixelFormat(Int) to Int {
    var RGBA = GL.RGBA;
    var SINGLE_CHANNEL = #if desktop 0x1903 /*RED*/ #else GL.LUMINANCE #end ;
}
