package net.rezmason.scourge.textview.core;

import flash.display.BitmapData;

import flash.utils.ByteArray;
import openfl.gl.GL;
import openfl.gl.GLBuffer;
import openfl.gl.GLFramebuffer;
import openfl.gl.GLRenderbuffer;
import openfl.gl.GLProgram;
import openfl.gl.GLTexture;
import openfl.gl.GLUniformLocation;
import openfl.utils.Float32Array;
import openfl.utils.Int16Array;
import openfl.utils.UInt8Array;

class VertexBuffer {

    @:allow(net.rezmason.scourge.textview.utils) var buf:GLBuffer;
    public var footprint(default, null):Int;
    public var numVertices(default, null):Int;
    var array:Float32Array;

    public function new(numVertices:Int, footprint:Int):Void {
        this.footprint = footprint;
        this.numVertices = numVertices;
        buf = GL.createBuffer();
        array = new Float32Array(footprint * numVertices);
    }

    public inline function uploadFromVector(data:Array<Float>, offset:Int = 0, num:Int = 0):Void {
        if (offset < 0 || offset > numVertices) {

        } else {
            if (offset + num > numVertices) num = numVertices - offset;

            for (ike in (offset * footprint)...((offset + num) * footprint)) {
                array[ike] = data[ike];
            }

            GL.bindBuffer(GL.ARRAY_BUFFER, buf);
            GL.bufferData(GL.ARRAY_BUFFER, array, GL.STATIC_DRAW);
        }
    }
}

class IndexBuffer {

    @:allow(net.rezmason.scourge.textview.utils) var buf:GLBuffer;
    public var numIndices(default, null):Int;
    var array:Int16Array;

    public function new(numIndices:Int):Void {
        this.numIndices = numIndices;
        buf = GL.createBuffer();
        array = new Int16Array(numIndices);
    }

    public inline function uploadFromVector(data:Array<Int>, offset:Int = 0, num:Int = 0):Void {
        if (offset < 0 || offset > numIndices) {

        } else {
            if (offset + num > numIndices) num = numIndices - offset;

            for (ike in offset...(offset + num)) {
                array[ike] = data[ike];
            }

            GL.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, buf);
            GL.bufferData(GL.ELEMENT_ARRAY_BUFFER, array, GL.STATIC_DRAW);
        }
    }
}

class OutputBuffer {

    @:allow(net.rezmason.scourge.textview.utils) var frameBuffer:GLFramebuffer;
    var texture:GLTexture;
    var renderBuffer:GLRenderbuffer;

    public function new(?empty:Bool):Void {

        if (!empty) {
            frameBuffer = GL.createFramebuffer();
            texture = GL.createTexture();
            renderBuffer = GL.createRenderbuffer();
        }
    }

    public function resize(width:Int, height:Int):Void {

        if (frameBuffer == null) {
            GL.viewport(0, 0, width, height);
        } else {
            GL.bindFramebuffer(GL.FRAMEBUFFER, frameBuffer);

            GL.bindTexture(GL.TEXTURE_2D, texture);
            GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.LINEAR);
            GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.LINEAR);

            GL.texImage2D(GL.TEXTURE_2D, 0, GL.RGBA, width, height, 0, GL.RGBA, GL.UNSIGNED_BYTE, null);

            GL.bindRenderbuffer(GL.RENDERBUFFER, renderBuffer);
            GL.renderbufferStorage(GL.RENDERBUFFER, GL.DEPTH_COMPONENT16, width, height);

            GL.framebufferTexture2D(GL.FRAMEBUFFER, GL.COLOR_ATTACHMENT0, GL.TEXTURE_2D, texture, 0);
            GL.framebufferRenderbuffer(GL.FRAMEBUFFER, GL.DEPTH_ATTACHMENT, GL.RENDERBUFFER, renderBuffer);

            GL.bindTexture(GL.TEXTURE_2D, null);
            GL.bindRenderbuffer(GL.RENDERBUFFER, null);
            GL.bindFramebuffer(GL.FRAMEBUFFER, null);
        }
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
