package net.rezmason.gl;

import lime.graphics.opengl.GL;
@:enum abstract DataType(Int) to Int {
    var FLOAT = GL.FLOAT;
    var HALF_FLOAT = 0x8D61;
    var UNSIGNED_BYTE = GL.UNSIGNED_BYTE;
}
