package net.rezmason.scourge.textview.core;

import flash.display.BitmapData;

import flash.utils.ByteArray;
import openfl.gl.GL;
import openfl.gl.GLBuffer;
import openfl.gl.GLProgram;
import openfl.gl.GLUniformLocation;
import openfl.utils.Float32Array;
import openfl.utils.Int16Array;
import openfl.utils.UInt8Array;

class VertexBuffer {

    public var buf:GLBuffer;
    public var footprint:Int;

    public function new(footprint:Int, ?data:Array<Float>):Void {
        this.footprint = footprint;
        buf = GL.createBuffer();
        if (data != null) uploadFromVector(data);
    }

    public inline function uploadFromVector(data:Array<Float>, offset:Int = 0, num:Int = 0):Void {
        GL.bindBuffer(GL.ARRAY_BUFFER, buf);
        GL.bufferData(GL.ARRAY_BUFFER, new Float32Array(data), GL.STATIC_DRAW);
    }
}

class IndexBuffer {

    public var buf:GLBuffer;
    public var count(default, null):Int;

    public function new(?data:Array<Int>):Void {
        buf = GL.createBuffer();
        count = 0;
        if (data != null) uploadFromVector(data);
    }

    public inline function uploadFromVector(data:Array<Int>, offset:Int = 0, num:Int = 0):Void {
        count = data.length;
        GL.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, buf);
        GL.bufferData(GL.ELEMENT_ARRAY_BUFFER, new Int16Array(data), GL.STATIC_DRAW);
    }
}

abstract Texture(BitmapData) {
    inline function new(bd:BitmapData):Void this = bd;
    @:from static public inline function fromBitmapData(bd:BitmapData):Texture return new Texture(bd);
}

abstract Program(GLProgram) {
    inline function new(prog:GLProgram):Void this = prog;
    public inline function getAttribLocation(name:String):Int return GL.getAttribLocation(this, name);
    public inline function getUniformLocation(name:String):GLUniformLocation return GL.getUniformLocation(this, name);
    @:from static public inline function fromGLProgram(program:GLProgram):Program return new Program(program);
    @:to public inline function toGLProgram():GLProgram return cast this;
}

class BlendFactor {
    public static inline var ZERO                   = GL.ZERO;
    public static inline var ONE                    = GL.ONE;
    public static inline var SRC_COLOR              = GL.SRC_COLOR;
    public static inline var ONE_MINUS_SRC_COLOR    = GL.ONE_MINUS_SRC_COLOR;
    public static inline var SRC_ALPHA              = GL.SRC_ALPHA;
    public static inline var ONE_MINUS_SRC_ALPHA    = GL.ONE_MINUS_SRC_ALPHA;
    public static inline var DST_ALPHA              = GL.DST_ALPHA;
    public static inline var ONE_MINUS_DST_ALPHA    = GL.ONE_MINUS_DST_ALPHA;
    public static inline var DST_COLOR              = GL.DST_COLOR;
    public static inline var ONE_MINUS_DST_COLOR    = GL.ONE_MINUS_DST_COLOR;
    public static inline var SRC_ALPHA_SATURATE     = GL.SRC_ALPHA_SATURATE;
}

typedef UniformLocation = GLUniformLocation;

#if js
    typedef ReadbackData = UInt8Array;
#else
    typedef ReadbackData = ByteArray;
#end
