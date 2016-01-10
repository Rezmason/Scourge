package net.rezmason.gl;

import lime.graphics.opengl.GL;
@:enum abstract BufferUsage(Int) to Int {
    var STATIC_DRAW = GL.STATIC_DRAW;
    var DYNAMIC_DRAW = GL.DYNAMIC_DRAW;
}
