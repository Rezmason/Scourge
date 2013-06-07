package com.wighawag.shaders.glsl;

import flash.Vector;
import flash.display3D.textures.Texture;
import flash.geom.Matrix3D;
import flash.display3D.Context3D;
import flash.display3D.Context3DProgramType;

class GLSLFragmentShader extends GLSLShader{

    public function new(glslSource : String){
        super(Context3DProgramType.FRAGMENT, glslSource);
    }

    public function setTextureAt(context3D : Context3D, name : String , texture : Texture){
        var registerIndex = getRegisterIndexForSampler(name);
        context3D.setTextureAt( registerIndex, texture);
    }

    override private function getRegisterIndexForUniform(name : String) : Int{
        var registerName = agalInfo.varnames.get(name);
        if(registerName == null){
            registerName = name;
        }
        return Std.parseInt(registerName.substr(2)); //fc
    }

    private function getRegisterIndexForSampler(name : String) : Int{
        var registerName = agalInfo.varnames.get(name);
        return Std.parseInt(registerName.substr(2)); //fs
    }

}
