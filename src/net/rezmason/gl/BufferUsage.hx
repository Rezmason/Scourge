package net.rezmason.gl;

#if flash
    //typedef BufferUsage = flash.display3D.Context3DBufferUsage;
    @:enum abstract BufferUsage(String) {
        var STATIC_DRAW = "staticDraw";
        var DYNAMIC_DRAW = "dynamicDraw";
    }
#else
    import openfl.gl.GL;
    @:enum abstract BufferUsage(Int) {
        var STATIC_DRAW = GL.STATIC_DRAW;
        var DYNAMIC_DRAW = GL.DYNAMIC_DRAW;
    }
#end

