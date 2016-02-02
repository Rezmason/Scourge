package net.rezmason.gl;

import lime.graphics.opengl.GL;
@:enum abstract PixelFormat(Int) to Int {
    var RGBA = GL.RGBA;
    var LUMINANCE = GL.LUMINANCE;
}
