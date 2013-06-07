package com.wighawag.shaders.glsl;

import flash.geom.Matrix3D;
import flash.display3D.textures.Texture;
import flash.display3D.Context3D;
import flash.display3D.VertexBuffer3D;
import flash.display3D.Context3DVertexBufferFormat;
import flash.display3D.Context3DProgramType;


class GLSLVertexShader extends GLSLShader{

    public function new(glslSource : String) {
        super(Context3DProgramType.VERTEX, glslSource);
    }

    public function setVertexBufferAt(context3D : Context3D, name : String, vertexBuffer : VertexBuffer3D, bufferOffset : Int, format : Context3DVertexBufferFormat) : Void{
        var registerIndex = getRegisterIndexForVarying(name);
        context3D.setVertexBufferAt(registerIndex, vertexBuffer, bufferOffset, format);
    }

    private function getRegisterIndexForVarying(name : String) : Int{
        var registerName = agalInfo.varnames.get(name);
        return Std.parseInt(registerName.substr(2)); //va
    }

    override private function getRegisterIndexForUniform(name : String) : Int{
        var registerName = agalInfo.varnames.get(name);
        if(registerName == null){
            registerName = name;
        }
        return Std.parseInt(registerName.substr(2)); //vc
    }

}
