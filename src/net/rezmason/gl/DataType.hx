package net.rezmason.gl;

import lime.graphics.opengl.GL;
@:enum abstract DataType(Int) to Int {
    var FLOAT = GL.FLOAT;
    var HALF_FLOAT = #if desktop 0x140B #else 0x8D61 #end;
    var UNSIGNED_BYTE = GL.UNSIGNED_BYTE;
}
