package net.rezmason.gl;

import lime.graphics.opengl.GL;
@:enum abstract TextureFormat(Int) to Int {
    var FLOAT = GL.FLOAT;
    var UNSIGNED_BYTE = GL.UNSIGNED_BYTE;
}
