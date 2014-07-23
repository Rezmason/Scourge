package net.rezmason.gl;

#if flash
    
#else
    import openfl.gl.GL;

    abstract BufferUsage(Int) {
        inline function new(val:Int):Void this = val;
        @:from static public inline function fromInt(val:Int):BufferUsage return new BufferUsage(val);
        @:to public inline function toInt():Int return cast this;

        public static inline var STATIC_DRAW:BufferUsage = GL.STATIC_DRAW;
        public static inline var DYNAMIC_DRAW:BufferUsage = GL.DYNAMIC_DRAW;
    }
#end

