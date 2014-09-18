package net.rezmason.gl;

#if flash
    //typedef BufferUsage = flash.display3D.Context3DBufferUsage;
    @:enum abstract BufferUsage(String) {
        @:to public inline function toString():String return cast this;
        var STATIC_DRAW = "staticDraw";
        var DYNAMIC_DRAW = "dynamicDraw";
    }
#else
    import openfl.gl.GL;
    @:enum abstract BufferUsage(Int) {
        @:to public inline function toInt():Int return cast this;
        var STATIC_DRAW = GL.STATIC_DRAW;
        var DYNAMIC_DRAW = GL.DYNAMIC_DRAW;
    }
#end

