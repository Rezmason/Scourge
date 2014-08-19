package net.rezmason.gl.glsl2agal;

import flash.display3D.Context3DProgramType;
import flash.utils.ByteArray;

typedef GLSLInput = {
    var type:Context3DProgramType;
    var source:String;
    @:optional var texParam:String;
}

typedef AGALOutput = {
    var type:Context3DProgramType;
    var nativeShader:ByteArray;
    var json:Dynamic;
    var error:Dynamic;
}
