package net.rezmason.scourge.textview.rendermethods;

import nme.display3D.Context3DBlendFactor;
import nme.display3D.Context3DCompareMode;
import nme.display3D.Context3DProgramType;
import nme.display3D.Context3DVertexBufferFormat;
import nme.geom.Matrix3D;

import net.rezmason.scourge.textview.core.BodySegment;
import net.rezmason.scourge.textview.core.GlyphTexture;
import net.rezmason.scourge.textview.core.RenderMethod;

/*
class PointShader extends hxsl.Shader {

    static var SRC = {
        var input : {
            pos : Float2,
        };
        var tuv : Float2;
        function vertex( mproj : Matrix, delta : Float4, size : Float2 ) {
            var p = delta * mproj;
            p.xy += input.pos.xy * size * p.z;
            out = p;
            tuv = input.pos;
        }
        function fragment( color : Color ) {
            kill( 1 - (tuv.x * tuv.x + tuv.y * tuv.y) );
            out = color;
        }
    }

}
*/

class MouseMethod extends RenderMethod {

    inline static var FAT_FINGERS:Float = 2;

    override public function activate():Void {
        programUtil.setProgram(program);
        programUtil.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO);
        programUtil.setDepthTest(false, Context3DCompareMode.LESS);
    }

    override public function deactivate():Void {
        programUtil.setVertexBufferAt(0, null, 0, Context3DVertexBufferFormat.FLOAT_3); // va0 is empty
        programUtil.setVertexBufferAt(1, null, 3, Context3DVertexBufferFormat.FLOAT_2); // va1 is empty
        programUtil.setVertexBufferAt(2, null, 0, Context3DVertexBufferFormat.FLOAT_3); // va2 is empty
    }

    override function init():Void {
        backgroundColor = 0xFFFFFF;
        glyphMag = FAT_FINGERS;
    }

    override function makeVertexShader():String {
        return [
            "m44 vt1 va1 vc5",  // corner = glyphMat.project(hv)

            "m44 vt0 va0 vc9",  // pos = bodyMat.project(xyz)
            "m44 vt0 vt0 vc1",  // pos = cameraMat.project(pos)
            "add vt0.xy vt0.xy vt1.xy",  // pos = corner.xy + projected

            "mov v0 va2", // f[0] = paint

            "mov op vt0",  // outputPosition = pos
        ].join("\n");
    }

    override function makeFragmentShader():String {
        return [
            "mov oc v0",
        ].join("\n");
    }

    override public function setGlyphTexture(glyphTexture:GlyphTexture, glyphTransform:Matrix3D):Void {
        super.setGlyphTexture(glyphTexture, glyphTransform);
        programUtil.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 5, glyphMat, true); // vc5 contains the character matrix
    }

    override public function setMatrices(cameraMat:Matrix3D, bodyMat:Matrix3D):Void {
        programUtil.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 1, cameraMat, true); // vc1 contains the camera matrix
        programUtil.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 9, bodyMat, true); // vc9 contains the body's matrix
    }

    override public function setSegment(segment:BodySegment):Void {
        programUtil.setVertexBufferAt(0, segment.shapeBuffer, 0, Context3DVertexBufferFormat.FLOAT_3); // va0 contains x,y,z
        programUtil.setVertexBufferAt(1, segment.shapeBuffer, 3, Context3DVertexBufferFormat.FLOAT_2); // va1 contains h,v
        programUtil.setVertexBufferAt(2, segment.paintBuffer, 0, Context3DVertexBufferFormat.FLOAT_3); // va2 contains paint
    }
}

