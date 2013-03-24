package net.rezmason.scourge.textview;

import com.adobe.utils.AGALMiniAssembler;
import nme.display3D.Program3D;
import nme.geom.Matrix3D;
import nme.utils.ByteArray;

import net.rezmason.scourge.textview.utils.ProgramUtil;
import net.rezmason.scourge.textview.utils.Types;

class Style {

    public var program(default, null):Program3D;
    public var backgroundColor(default, null):Int;
    var programUtil:ProgramUtil;
    var glyphMat:Matrix3D;
    var glyphMag:Float;

    public function new(programUtil:ProgramUtil):Void {
        this.programUtil = programUtil;
        program = programUtil.createProgram();
        glyphMag = 1;
        backgroundColor = 0x0;
        glyphMat = new Matrix3D();
        init();
        var assembler:AGALMiniAssembler = new AGALMiniAssembler();
        var vertexShader:ByteArray = assembler.assemble("vertex", makeVertexShader());
        var fragmentShader:ByteArray = assembler.assemble("fragment", makeFragmentShader());
        program.upload(vertexShader, fragmentShader);
    }

    public function setMatrices(cameraMat:Matrix3D, modelMat:Matrix3D):Void { }
    public function activate():Void { }
    public function deactivate():Void { }

    public function setGlyphTexture(glyphTexture:GlyphTexture, aspectRatio:Float):Void {
        glyphMat.copyFrom(glyphTexture.matrix);
        if (aspectRatio < 1) {
            glyphMat.appendScale(1, aspectRatio, 1);
        } else {
            glyphMat.appendScale(1 / aspectRatio, 1, 1);
        }
        glyphMat.appendScale(glyphMag, glyphMag, 1);
    }

    public function setSegment(segment:ModelSegment):Void { }
    function init():Void { }
    function makeVertexShader():String { return ""; }
    function makeFragmentShader():String { return ""; }
}

