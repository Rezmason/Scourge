package net.rezmason.scourge.textview.rendermethods;

import flash.geom.Matrix3D;
import openfl.gl.GLUniformLocation;

import net.rezmason.scourge.textview.core.BodySegment;
import net.rezmason.scourge.textview.core.GlyphTexture;
import net.rezmason.scourge.textview.core.RenderMethod;
import net.rezmason.scourge.textview.core.Types;

class MouseMethod extends RenderMethod {

    //inline static var FAT_FINGERS:Float = 2; // TODO: Fat finger support needs to wait till we can z-order buttons

    var posLoc:Int;
    var cornerLoc:Int;
    var paintLoc:Int;
    var uCameraMat:GLUniformLocation;
    var uGlyphMat:GLUniformLocation;
    var uBodyMat:GLUniformLocation;

    override public function activate():Void {
        programUtil.setProgram(program);
        programUtil.setBlending(false);
        programUtil.setDepthTest(true);
    }

    override public function deactivate():Void {
        programUtil.setVertexBufferAt(posLoc,    null, 0, 3);
        programUtil.setVertexBufferAt(cornerLoc, null, 3, 2);
        programUtil.setVertexBufferAt(paintLoc,  null, 0, 3);
    }

    override function init():Void {
        super.init();
        backgroundColor = 0xFFFFFF;
        //glyphMag = FAT_FINGERS;
    }

    override function composeShaders():Void {
        vertShader = '
            attribute vec3 posLoc;
            attribute vec2 cornerLoc;
            attribute vec3 paintLoc;

            uniform mat4 uCameraMat;
            uniform mat4 uGlyphMat;
            uniform mat4 uBodyMat;

            varying vec4 vPaint;

            void main(void) {

                vPaint = vec4(paintLoc, 1.0);

                vec4 pos = uCameraMat * uBodyMat * vec4(posLoc, 1.0);
                pos.xy += (uGlyphMat * vec4(cornerLoc, 1.0, 1.0)).xy;

                gl_Position = pos;
            }
        ';

        fragShader =
            #if !desktop 'precision mediump float;' + #end
            '
            varying vec4 vPaint;

            void main(void) {
                gl_FragColor = vPaint;
            }
        ';
    }

    override function connectToShaders():Void {
        posLoc     = program.getAttribLocation('posLoc');
        cornerLoc  = program.getAttribLocation('cornerLoc');
        paintLoc   = program.getAttribLocation('paintLoc');

        uCameraMat = program.getUniformLocation('uCameraMat');
        uGlyphMat  = program.getUniformLocation('uGlyphMat');
        uBodyMat   = program.getUniformLocation('uBodyMat');
    }

    override public function setGlyphTexture(glyphTexture:GlyphTexture, glyphTransform:Matrix3D):Void {
        super.setGlyphTexture(glyphTexture, glyphTransform);
        programUtil.setProgramConstantsFromMatrix(uGlyphMat, glyphMat);
    }

    override public function setMatrices(cameraMat:Matrix3D, bodyMat:Matrix3D):Void {
        programUtil.setProgramConstantsFromMatrix(uCameraMat, cameraMat);
        programUtil.setProgramConstantsFromMatrix(uBodyMat, bodyMat);
    }

    override public function setSegment(segment:BodySegment):Void {
        programUtil.setVertexBufferAt(posLoc,    segment.shapeBuffer, 0, 3);
        programUtil.setVertexBufferAt(cornerLoc, segment.shapeBuffer, 3, 2);
        programUtil.setVertexBufferAt(paintLoc,  segment.paintBuffer, 0, 3);
    }
}

