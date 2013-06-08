package com.wighawag.shaders.glsl;

import flash.display3D.textures.Texture;
import flash.display3D.Context3D;
import flash.display3D.Context3DProgramType;

class GLSLFragmentShader extends GLSLShader{

    public function new(glslSource : String){
        super(Context3DProgramType.FRAGMENT, glslSource);
    }

    public inline function setTextureAt(context3D : Context3D, index : Int , texture : Texture){
        context3D.setTextureAt( index, texture);
    }

}
