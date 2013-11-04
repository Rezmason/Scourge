package net.rezmason.gl.glsl2agal;

import net.rezmason.gl.glsl2agal.Types;
import net.rezmason.utils.TempWorker;

/**

    The net.rezmason.gl.glsl2agal package is derived from the NME contributions
    of Ronan Sandford (aka @wighawag) toward cross-platform Stage3D support:

    https://github.com/wighawag/NMEStage3DTest

    While functional, the code included here and in the net.rezmason.gl package
    do not represent the primary efforts of the OpenFL community toward a fully
    cross-platform 3D API.

**/

class Converter {

    static var worker:TempWorker<GLSLInput, AGALOutput> = new TempWorker(convert);

    static function convert(input:GLSLInput):AGALOutput {
        var type:String = cast input.type;
        var source = input.source;
        var json = haxe.JSON.Json.parse((new nme.display3D.shaders.GlslToAgal(source, type, true, true)).compile());
        var assembler = new com.adobe.utils.AGALMiniAssembler();
        assembler.assemble(type, json.agalasm);
        return {type:input.type, json:json, nativeShader:assembler.agalcode};
    }
}
