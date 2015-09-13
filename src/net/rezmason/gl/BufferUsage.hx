package net.rezmason.gl;

#if flash
    //typedef BufferUsage = flash.display3D.Context3DBufferUsage;
    @:enum abstract BufferUsage(String) to String {
        var STATIC_DRAW = "staticDraw";
        var DYNAMIC_DRAW = "dynamicDraw";
    }
#else
    import lime.graphics.opengl.GL;
    @:enum abstract BufferUsage(Int) to Int {
        var STATIC_DRAW = GL.STATIC_DRAW;
        var DYNAMIC_DRAW = GL.DYNAMIC_DRAW;
    }
#end

