package net.rezmason.scourge.textview.rendermethods;

import flash.geom.Matrix3D;

import openfl.Assets.getText;

import net.rezmason.scourge.textview.core.Almanac.*;
import net.rezmason.scourge.textview.core.BodySegment;
import net.rezmason.scourge.textview.core.GlyphTexture;
import net.rezmason.scourge.textview.core.RenderMethod;
import net.rezmason.gl.BlendFactor;
import net.rezmason.gl.Types;
import net.rezmason.gl.VertexBuffer;

class PrettyMethod extends RenderMethod {

    var aPos:AttribsLocation;
    var aCorner:AttribsLocation;
    var aScale:AttribsLocation;
    var aPop:AttribsLocation;
    var aColor:AttribsLocation;
    var aUV:AttribsLocation;
    var aVid:AttribsLocation;
    var aFat:AttribsLocation;
    var uSampler:UniformLocation;
    var uGlyphMat:UniformLocation;
    var uCameraMat:UniformLocation;
    var uBodyMat:UniformLocation;

    public function new():Void super();

    override public function activate():Void {
        programUtil.setProgram(program);
        programUtil.setBlendFactors(BlendFactor.ONE, BlendFactor.ONE);
        programUtil.setDepthTest(false);
    }

    override public function deactivate():Void {
        programUtil.setTextureAt(program, uSampler, null);
        programUtil.setBlendFactors(BlendFactor.ONE, BlendFactor.ZERO);
        programUtil.setDepthTest(true);
    }

    override function composeShaders():Void {
        vertShader = getText('shaders/scourge_glyphs.vert');
        fragShader = #if !desktop 'precision mediump float;' + #end getText('shaders/scourge_glyphs.frag');
    }

    override function connectToShaders():Void {

        aPos    = programUtil.getAttribsLocation(program, 'aPos'   );
        aCorner = programUtil.getAttribsLocation(program, 'aCorner');
        aScale  = programUtil.getAttribsLocation(program, 'aScale' );
        aPop    = programUtil.getAttribsLocation(program, 'aPop'   );
        aColor  = programUtil.getAttribsLocation(program, 'aColor' );
        aUV     = programUtil.getAttribsLocation(program, 'aUV'    );
        aVid    = programUtil.getAttribsLocation(program, 'aVid'   );
        aFat    = programUtil.getAttribsLocation(program, 'aFat'   );

        uSampler   = programUtil.getUniformLocation(program, 'uSampler'  );
        uGlyphMat  = programUtil.getUniformLocation(program, 'uGlyphMat' );
        uCameraMat = programUtil.getUniformLocation(program, 'uCameraMat');
        uBodyMat   = programUtil.getUniformLocation(program, 'uBodyMat'  );
    }

    override public function setGlyphTexture(glyphTexture:GlyphTexture, glyphTransform:Matrix3D):Void {
        super.setGlyphTexture(glyphTexture, glyphTransform);
        programUtil.setProgramConstantsFromMatrix(program, uGlyphMat, glyphMat); // uGlyphMat contains the character matrix
        programUtil.setTextureAt(program, uSampler, glyphTexture.texture); // uSampler contains our texture
    }

    override public function setMatrices(cameraMat:Matrix3D, bodyMat:Matrix3D):Void {
        programUtil.setProgramConstantsFromMatrix(program, uCameraMat, cameraMat); // uCameraMat contains the camera matrix
        programUtil.setProgramConstantsFromMatrix(program, uBodyMat, bodyMat); // uBodyMat contains the body's matrix
    }

    override public function setSegment(segment:BodySegment):Void {

        var shapeBuffer:VertexBuffer = null;
        var colorBuffer:VertexBuffer = null;

        if (segment != null) {
            shapeBuffer = segment.shapeBuffer;
            colorBuffer = segment.colorBuffer;
        }

        programUtil.setVertexBufferAt(program, aPos,    shapeBuffer, 0, 3); // aPos contains x,y,z
        programUtil.setVertexBufferAt(program, aCorner, shapeBuffer, 3, 2); // aCorner contains h,v
        programUtil.setVertexBufferAt(program, aScale,  shapeBuffer, 5, 1); // aScale contains s
        programUtil.setVertexBufferAt(program, aPop,    shapeBuffer, 6, 1); // aPop contains p
        programUtil.setVertexBufferAt(program, aColor,  colorBuffer, 0, 3); // aColor contains r,g,b
        programUtil.setVertexBufferAt(program, aUV,     colorBuffer, 3, 2); // aUV contains u,v
        programUtil.setVertexBufferAt(program, aVid,    colorBuffer, 5, 1); // aVid contains i
        programUtil.setVertexBufferAt(program, aFat,    colorBuffer, 6, 1); // aFat contains f
    }
}

