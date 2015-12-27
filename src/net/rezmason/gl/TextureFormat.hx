package net.rezmason.gl;

#if ogl
    import lime.graphics.opengl.GL;
    @:enum abstract TextureFormat(Int) to Int {
        var FLOAT = GL.FLOAT;
        var UNSIGNED_BYTE = GL.UNSIGNED_BYTE;
    }
#end
