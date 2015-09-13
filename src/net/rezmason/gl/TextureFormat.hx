package net.rezmason.gl;

#if !flash
    import lime.graphics.opengl.GL;
#end

#if flash
    @:enum abstract TextureFormat(String) to String {
        var FLOAT = "rgbaHalfFloat"; // Context3DTextureFormat.RGBA_HALF_FLOAT
    }
#else
    @:enum abstract TextureFormat(Int) to Int {
        var FLOAT = GL.FLOAT;
        var UNSIGNED_BYTE = GL.UNSIGNED_BYTE;
    }
#end
