package net.rezmason.gl;

#if !flash
    import openfl.gl.GL;
#end

#if flash
    @:enum abstract TextureFormat(String) {
        @:to public inline function toString():String return cast this;
        var FLOAT = "rgbaHalfFloat"; // Context3DTextureFormat.RGBA_HALF_FLOAT
    }
#else
    @:enum abstract TextureFormat(Int) {
        @:to public inline function toInt():Int return cast this;
        var FLOAT = GL.FLOAT;
        var UNSIGNED_BYTE = GL.UNSIGNED_BYTE;
    }
#end
