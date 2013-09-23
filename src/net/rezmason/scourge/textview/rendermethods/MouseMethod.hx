package net.rezmason.scourge.textview.rendermethods;

import flash.geom.Matrix3D;

import openfl.Assets.getText;

import net.rezmason.scourge.textview.core.BodySegment;
import net.rezmason.scourge.textview.core.GlyphTexture;
import net.rezmason.scourge.textview.core.RenderMethod;
import net.rezmason.gl.BlendFactor;
import net.rezmason.gl.Types;

class MouseMethod extends RenderMethod {

    //inline static var FAT_FINGERS:Float = 2; // TODO: Fat finger support needs to wait till we can z-order buttons

    var aPos:AttribsLocation;
    var aCorner:AttribsLocation;
    var aPaint:AttribsLocation;

    var uGlyphMat:UniformLocation;
    var uCameraMat:UniformLocation;
    var uBodyMat:UniformLocation;

    public function new():Void super();

    override public function activate():Void {
        programUtil.setProgram(program);
    }

    override public function deactivate():Void {
        programUtil.setVertexBufferAt(program, aPos,    null, 0, 3);
        programUtil.setVertexBufferAt(program, aCorner, null, 3, 2);
        programUtil.setVertexBufferAt(program, aPaint,  null, 0, 3);
    }

    override function init():Void {
        super.init();
        backgroundColor = 0xFFFFFF;
        //glyphMag = FAT_FINGERS;
    }

    override function composeShaders():Void {
        vertShader = getText('shaders/mousepicking.vert');
        fragShader = #if !desktop 'precision mediump float;' + #end getText('shaders/mousepicking.frag');
    }

    override function connectToShaders():Void {
        aPos    = programUtil.getAttribsLocation(program, 'aPos'   );
        aCorner = programUtil.getAttribsLocation(program, 'aCorner');
        aPaint  = programUtil.getAttribsLocation(program, 'aPaint' );

        uGlyphMat  = programUtil.getUniformLocation(program, 'uGlyphMat' );
        uCameraMat = programUtil.getUniformLocation(program, 'uCameraMat');
        uBodyMat   = programUtil.getUniformLocation(program, 'uBodyMat'  );
    }

    override public function setGlyphTexture(glyphTexture:GlyphTexture, glyphTransform:Matrix3D):Void {
        super.setGlyphTexture(glyphTexture, glyphTransform);
        programUtil.setProgramConstantsFromMatrix(program, uGlyphMat, glyphMat);
    }

    override public function setMatrices(cameraMat:Matrix3D, bodyMat:Matrix3D):Void {
        programUtil.setProgramConstantsFromMatrix(program, uCameraMat, cameraMat);
        programUtil.setProgramConstantsFromMatrix(program, uBodyMat, bodyMat);
    }

    override public function setSegment(segment:BodySegment):Void {
        programUtil.setVertexBufferAt(program, aPos,    segment.shapeBuffer, 0, 3);
        programUtil.setVertexBufferAt(program, aCorner, segment.shapeBuffer, 3, 2);
        programUtil.setVertexBufferAt(program, aPaint,  segment.paintBuffer, 0, 3);
    }
}

