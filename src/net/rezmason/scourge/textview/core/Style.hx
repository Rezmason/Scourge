package net.rezmason.scourge.textview.core;

import com.adobe.utils.AGALMiniAssembler;
import nme.display3D.Program3D;
import nme.geom.Matrix3D;
import nme.geom.Vector3D;
import nme.utils.ByteArray;

import net.rezmason.scourge.textview.utils.ProgramUtil;
import net.rezmason.scourge.textview.utils.Types;

class Style {

    inline static var MAG_LIMIT:Float = 0.7;
    static var unitVec:Vector3D = new Vector3D(1, 0, 0);

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

    public function setMatrices(cameraMat:Matrix3D, bodyMat:Matrix3D):Void { }
    public function activate():Void { }
    public function deactivate():Void { }

    public function setGlyphTexture(glyphTexture:GlyphTexture, glyphTransform:Matrix3D):Void {
        glyphMat.copyFrom(glyphTexture.matrix);
        glyphMat.append(glyphTransform);
        glyphMat.appendScale(glyphMag, glyphMag, 1);

        // mag fuse
        if (glyphMat.transformVector(unitVec).length > MAG_LIMIT) throw "You blew the mag fuse!";
    }

    public function setSegment(segment:BodySegment):Void { }
    function init():Void { }
    function makeVertexShader():String { return ""; }
    function makeFragmentShader():String { return ""; }
}

