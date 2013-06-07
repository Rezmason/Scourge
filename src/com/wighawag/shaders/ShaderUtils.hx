package com.wighawag.shaders;

import com.adobe.utils.AGALMiniAssembler;
import flash.display3D.Context3DProgramType;

class ShaderUtils {

    inline public static function createShader (type: Context3DProgramType, shaderSource:String): com.wighawag.shaders.Shader {

        var assembler = new AGALMiniAssembler ();
        assembler.assemble (cast(type,String), shaderSource);
        return assembler.agalcode;
    }
}
