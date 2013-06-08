package com.wighawag.shaders.glsl;

import flash.display3D.Context3D;
import flash.display3D.VertexBuffer3D;
import flash.display3D.Context3DVertexBufferFormat;
import flash.display3D.Context3DProgramType;

class GLSLVertexShader extends GLSLShader{

    public function new(glslSource : String) {
        super(Context3DProgramType.VERTEX, glslSource);
    }

    public function setVertexBufferAt(context3D : Context3D, index : Int, vertexBuffer : VertexBuffer3D, bufferOffset : Int, format : Context3DVertexBufferFormat) : Void{
        context3D.setVertexBufferAt(index, vertexBuffer, bufferOffset, format);
    }

}
