package net.rezmason.gl;

#if flash
    typedef BlendFactor = flash.display3D.Context3DBlendFactor;
#else
    import openfl.gl.GL;

    abstract BlendFactor(Int) {
        inline function new(val:Int):Void this = val;
        @:from static public inline function fromInt(val:Int):BlendFactor return new BlendFactor(val);
        @:to public inline function toInt():Int return cast this;

        public static inline var ZERO                  :BlendFactor = GL.ZERO;
        public static inline var ONE                   :BlendFactor = GL.ONE;
        public static inline var SRC_COLOR             :BlendFactor = GL.SRC_COLOR;
        public static inline var ONE_MINUS_SRC_COLOR   :BlendFactor = GL.ONE_MINUS_SRC_COLOR;
        public static inline var SRC_ALPHA             :BlendFactor = GL.SRC_ALPHA;
        public static inline var ONE_MINUS_SRC_ALPHA   :BlendFactor = GL.ONE_MINUS_SRC_ALPHA;
        public static inline var DST_ALPHA             :BlendFactor = GL.DST_ALPHA;
        public static inline var ONE_MINUS_DST_ALPHA   :BlendFactor = GL.ONE_MINUS_DST_ALPHA;
        public static inline var DST_COLOR             :BlendFactor = GL.DST_COLOR;
        public static inline var ONE_MINUS_DST_COLOR   :BlendFactor = GL.ONE_MINUS_DST_COLOR;
        public static inline var SRC_ALPHA_SATURATE    :BlendFactor = GL.SRC_ALPHA_SATURATE;
    }
#end
