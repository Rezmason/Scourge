package net.rezmason.gl.glsl2agal;

import flash.display3D.Context3DProgramType;
import haxe.io.Bytes;
import haxe.Json;
import com.adobe.utils.AGALMiniAssembler;
import net.rezmason.gl.glsl2agal.GLSL2AGALTypes;
import net.rezmason.utils.workers.BasicWorker;

/**

    The net.rezmason.gl.glsl2agal package is derived from the NME contributions
    of Ronan Sandford (aka @wighawag) toward cross-platform Stage3D support:

    https://github.com/wighawag/NMEStage3DTest

    While functional, the code included here and in the net.rezmason.gl package
    do not represent the primary efforts of the OpenFL community toward a fully
    cross-platform 3D API.

**/

class Converter extends BasicWorker<GLSLInput, AGALOutput> {

    inline static var AGAL_VERSION:Int = 2;

    static var cModuleInitialized:Bool = false;
    static var assembler:AGALMiniAssembler;

    override function process(data:GLSLInput):AGALOutput return convert(data);

    static function convert(input:GLSLInput):AGALOutput {
        var isFrag:Int = input.type == Context3DProgramType.FRAGMENT ? 1 : 0;
        var optimize = true;
        var usegles = true;

        var nativeShader = null;
        var json = null;
        var jsonString = null;
        var assemblerError = null;

        if (!cModuleInitialized) {
            untyped __global__["com.adobe.glsl2agal.CModule"].startAsync();
            cModuleInitialized = true;
        }

        jsonString = untyped __global__["com.adobe.glsl2agal.compileShader"](
            input.source, 
            isFrag, 
            optimize, 
            usegles
        );

        if (assembler == null) assembler = new AGALMiniAssembler();

        json = Json.parse(jsonString);

        var asm = json.agalasm;
        if (input.texParam != null) {
            asm = ~/<linear mipdisable repeat 2d>/g.replace(asm, input.texParam);
        }

        assembler.assemble(cast input.type, asm, AGAL_VERSION);
        nativeShader = Bytes.ofData(assembler.agalcode);
        if (assembler.error != null && assembler.error.length > 0) assemblerError = assembler.error;

        return {type:input.type, json:json, nativeShader:nativeShader, assemblerError:assemblerError};
    }
}
