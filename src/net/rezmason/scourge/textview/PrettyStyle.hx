package net.rezmason.scourge.textview;

import nme.display3D.Context3DBlendFactor;
import nme.display3D.Context3DCompareMode;
import nme.display3D.Context3DProgramType;
import nme.display3D.Context3DVertexBufferFormat;
import nme.geom.Matrix3D;
import nme.Vector;

class PrettyStyle extends Style {

    override public function activate():Void {
        programUtil.setProgram(program);
        programUtil.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ONE);
        programUtil.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, Vector.ofArray([2,0.3,0,0]), 1); // fc0 contains 2, 0.3
        programUtil.setDepthTest(false, Context3DCompareMode.LESS);
    }

    override public function deactivate():Void {
        programUtil.setTextureAt(0, null); // fs0 is empty
        programUtil.setVertexBufferAt(0, null, 0, Context3DVertexBufferFormat.FLOAT_3); // va0 is empty
        programUtil.setVertexBufferAt(1, null, 3, Context3DVertexBufferFormat.FLOAT_2); // va1 is empty
        programUtil.setVertexBufferAt(2, null, 5, Context3DVertexBufferFormat.FLOAT_1); // va2 is empty
        programUtil.setVertexBufferAt(3, null, 6, Context3DVertexBufferFormat.FLOAT_1); // va3 is empty
        programUtil.setVertexBufferAt(4, null, 0, Context3DVertexBufferFormat.FLOAT_3); // va4 is empty
        programUtil.setVertexBufferAt(5, null, 3, Context3DVertexBufferFormat.FLOAT_2); // va5 is empty
        programUtil.setVertexBufferAt(6, null, 5, Context3DVertexBufferFormat.FLOAT_1); // va6 is empty
    }

    override function makeVertexShader():String {
        return [
            "m44 vt1 va1 vc5",  // corner = glyphMat.project(hv)
            "mul vt1.xy vt1.xy va2.xx", // corner *= s

            "m44 vt0 va0 vc9",  // pos = modelMat.project(xyz)
            "add vt0.z vt0.z va3.x", // pos.z += p
            "m44 vt0 vt0 vc1",  // pos = cameraMat.project(pos)
            "add vt0.xy vt0.xy vt1.xy",  // pos = corner.xy + projected

            "mov v0 va4",        // fInput[0] = rgba
            "mov v1 va5",        // fInput[1] = uv
            "mov v2 va6",        // fInput[2] = i
            "mov v3 vt0.zzzz",   // fInput[3] = pos.z

            "sat vt0.z vt0.z", // flatten the z that go beyond the frustum

            "mov op vt0",  // outputPosition = pos
        ].join("\n");
    }

    override function makeFragmentShader():String {
        return [

            "tex ft0 v1 fs0 <2d, linear, miplinear, repeat>",   // glyph = textures[0].colorAt(fInput[1])

            // brightness = (i >= brightThreshold) ? i - glyph : i + glyph
            "sge ft1 fc0.yyyy v2.xxxx",    // isBright = (fInput[2] >= brightThreshold) ? 1 : 0     0 to 1
            "mul ft1 fc0.xxxx ft1",        // isBright *= brightMult                           0 to 2
            "mul ft1 ft0 ft1",        // isBright *= glyph                                 0 to 2*glyph
            "sub ft1 ft1 ft0",        // isBright -= brightSub                            -glyph to glyph
            "add ft1 ft1 v2.xxxx",    // brightness = fInput[2] + isBright

            // brightness *= (2 - z)
            "sub ft0 fc0.xxxx v3",
            "sat ft0 ft0",
            "mul ft1 ft1 ft0",

            "mul oc ft1 v0",          // outputColor = brightness * fInput[0]

        ].join("\n");
    }

    override public function setGlyphTexture(glyphTexture:GlyphTexture, aspectRatio:Float):Void {
        super.setGlyphTexture(glyphTexture, aspectRatio);
        programUtil.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 5, glyphMat, true); // vc5 contains the character matrix
        programUtil.setTextureAt(0, glyphTexture.texture); // fs0 contains our texture
    }

    override public function setMatrices(cameraMat:Matrix3D, modelMat:Matrix3D):Void {
        programUtil.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 1, cameraMat, true); // vc1 contains the camera matrix
        programUtil.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 9, modelMat, true); // vc9 contains the model's matrix
    }

    override public function setSegment(segment:ModelSegment):Void {
        programUtil.setVertexBufferAt(0, segment.shapeBuffer, 0, Context3DVertexBufferFormat.FLOAT_3); // va0 contains x,y,z
        programUtil.setVertexBufferAt(1, segment.shapeBuffer, 3, Context3DVertexBufferFormat.FLOAT_2); // va1 contains h,v
        programUtil.setVertexBufferAt(2, segment.shapeBuffer, 5, Context3DVertexBufferFormat.FLOAT_1); // va2 contains s
        programUtil.setVertexBufferAt(3, segment.shapeBuffer, 6, Context3DVertexBufferFormat.FLOAT_1); // va3 contains p
        programUtil.setVertexBufferAt(4, segment.colorBuffer, 0, Context3DVertexBufferFormat.FLOAT_3); // va4 contains r,g,b
        programUtil.setVertexBufferAt(5, segment.colorBuffer, 3, Context3DVertexBufferFormat.FLOAT_2); // va5 contains u,v
        programUtil.setVertexBufferAt(6, segment.colorBuffer, 5, Context3DVertexBufferFormat.FLOAT_1); // va6 contains i
    }
}

