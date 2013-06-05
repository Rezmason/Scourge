package net.rezmason.gl;

import openfl.gl.GL;
import openfl.gl.GLProgram;
import openfl.gl.GLUniformLocation;

abstract Program(GLProgram) {
    inline function new(prog:GLProgram):Void this = prog;
    public inline function getAttribLocation(name:String):Int return GL.getAttribLocation(this, name);
    public inline function getUniformLocation(name:String):GLUniformLocation return GL.getUniformLocation(this, name);
    @:from static public inline function fromGLProgram(program:GLProgram):Program return new Program(program);
    @:to public inline function toGLProgram():GLProgram return cast this;
}
