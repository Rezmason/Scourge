package net.rezmason.scourge.textview.core.rendermethods;

import flash.geom.Matrix3D;

import openfl.Assets.getText;

import net.rezmason.scourge.textview.core.Almanac.*;
import net.rezmason.scourge.textview.core.BodySegment;
import net.rezmason.scourge.textview.core.GlyphTexture;
import net.rezmason.scourge.textview.core.RenderMethod;
import net.rezmason.gl.BlendFactor;
import net.rezmason.gl.Data;
import net.rezmason.gl.VertexBuffer;

class PrettyMethod extends RenderMethod {

    inline static var DERIV_MULT:Float =
    #if flash
        0.3
    #elseif js
        80
    #else
        80
    #end
    ;

    var aPos:AttribsLocation;
    var aCorner:AttribsLocation;
    var aDistort:AttribsLocation;
    var aColor:AttribsLocation;
    var aUV:AttribsLocation;
    var aFX:AttribsLocation;
    var uSampler:UniformLocation;
    var uDerivMult:UniformLocation;
    var uGlyphMat:UniformLocation;
    var uCameraMat:UniformLocation;
    var uBodyMat:UniformLocation;

    public function new():Void super();

    override public function activate():Void {
        programUtil.setProgram(program);
        programUtil.setBlendFactors(BlendFactor.ONE, BlendFactor.ONE);
        programUtil.setDepthTest(false);

        program.setFourProgramConstants(uDerivMult, [DERIV_MULT, 0, 0, 0]);
    }

    override public function deactivate():Void {
        program.setTextureAt(uSampler, null);
        programUtil.setBlendFactors(BlendFactor.ONE, BlendFactor.ZERO);
        programUtil.setDepthTest(true);
    }

    override function composeShaders():Void {
        vertShader = getText('shaders/scourge_glyphs.vert');

        var frag:String = getText('shaders/scourge_glyphs.frag');

        #if flash
            fragShader = getText('shaders/scourge_glyphs_flash.frag');
        #elseif js
            programUtil.enableExtension("OES_standard_derivatives");
            fragShader = '#extension GL_OES_standard_derivatives : enable \n precision mediump float;' + frag;
        #else
            fragShader = frag;
        #end
    }

    override function connectToShaders():Void {

        aPos     = program.getAttribsLocation('aPos'    );
        aCorner  = program.getAttribsLocation('aCorner' );
        aDistort = program.getAttribsLocation('aDistort');
        aColor   = program.getAttribsLocation('aColor'  );
        aUV      = program.getAttribsLocation('aUV'     );
        aFX      = program.getAttribsLocation('aFX'     );
        
        uSampler   = program.getUniformLocation('uSampler'  );
        uDerivMult = program.getUniformLocation('uDerivMult');
        uGlyphMat  = program.getUniformLocation('uGlyphMat' );
        uCameraMat = program.getUniformLocation('uCameraMat');
        uBodyMat   = program.getUniformLocation('uBodyMat'  );
    }

    override public function setGlyphTexture(glyphTexture:GlyphTexture, glyphTransform:Matrix3D):Void {
        super.setGlyphTexture(glyphTexture, glyphTransform);
        program.setProgramConstantsFromMatrix(uGlyphMat, glyphMat); // uGlyphMat contains the character matrix
        program.setTextureAt(uSampler, glyphTexture.texture); // uSampler contains our texture
    }

    override public function setMatrices(cameraMat:Matrix3D, bodyMat:Matrix3D):Void {
        program.setProgramConstantsFromMatrix(uCameraMat, cameraMat); // uCameraMat contains the camera matrix
        program.setProgramConstantsFromMatrix(uBodyMat, bodyMat); // uBodyMat contains the body's matrix
    }

    override public function setSegment(segment:BodySegment):Void {

        var shapeBuffer:VertexBuffer = null;
        var colorBuffer:VertexBuffer = null;

        if (segment != null) {
            shapeBuffer = segment.shapeBuffer;
            colorBuffer = segment.colorBuffer;
        }

        program.setVertexBufferAt(aPos,     shapeBuffer, 0, 3); // aPos contains x,y,z
        program.setVertexBufferAt(aCorner,  shapeBuffer, 3, 2); // aCorner contains h,v
        program.setVertexBufferAt(aDistort, shapeBuffer, 5, 3); // aScale contains h,s,p
        program.setVertexBufferAt(aColor,   colorBuffer, 0, 3); // aColor contains r,g,b
        program.setVertexBufferAt(aUV,      colorBuffer, 3, 2); // aUV contains u,v
        program.setVertexBufferAt(aFX,      colorBuffer, 5, 3); // aFX contains i,f,a
    }
}

