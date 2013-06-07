package net.rezmason.gl;

#if flash
    typedef Program = com.wighawag.shaders.glsl.GLSLProgram;
#else
    import openfl.gl.GL;
    import openfl.gl.GLProgram;

    abstract Program(GLProgram) {
        inline function new(prog:GLProgram):Void this = prog;
        @:from static public inline function fromGLProgram(program:GLProgram):Program return new Program(program);
        @:to public inline function toGLProgram():GLProgram return cast this;
    }

#end
