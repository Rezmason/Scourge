package net.rezmason.scourge.textview.rendermethods;

import flash.geom.Matrix3D;
import openfl.gl.GLUniformLocation;
// import openfl.utils.Float32Array;

import net.rezmason.scourge.textview.core.BodySegment;
import net.rezmason.scourge.textview.core.GlyphTexture;
import net.rezmason.scourge.textview.core.RenderMethod;
import net.rezmason.scourge.textview.core.Types;

class PrettyMethod extends RenderMethod {

    var posLoc:Int;
    var cornerLoc:Int;
    var scaleLoc:Int;
    var popLoc:Int;
    var colorLoc:Int;
    var textureLoc:Int;
    var vidLoc:Int;
    var uCameraMat:GLUniformLocation;
    var uGlyphMat:GLUniformLocation;
    var uBodyMat:GLUniformLocation;
    var uSampler:GLUniformLocation;
    // var uCrap:GLUniformLocation;

    override public function activate():Void {
        programUtil.setProgram(program);
        programUtil.setBlendFactors(BlendFactor.ONE, BlendFactor.ONE);
        programUtil.setBlending(true);
        programUtil.setDepthTest(false);

        // TODO: these constants should go in the GLSL
        // programUtil.setProgramConstantsFromVector(uCrap, new Float32Array([2,0.3,0,0])); // uCrap contains 2, 0.3
    }

    override public function deactivate():Void {
        programUtil.setVertexBufferAt(posLoc,     null, 0, 3);
        programUtil.setVertexBufferAt(cornerLoc,  null, 3, 2);
        programUtil.setVertexBufferAt(scaleLoc,   null, 5, 1);
        programUtil.setVertexBufferAt(popLoc,     null, 6, 1);
        programUtil.setVertexBufferAt(colorLoc,   null, 0, 3);
        programUtil.setVertexBufferAt(textureLoc, null, 3, 2);
        programUtil.setVertexBufferAt(vidLoc,     null, 5, 1);
    }

    override function composeShaders():Void {
        vertShader = '
            attribute vec3 posLoc;
            attribute vec2 cornerLoc;
            attribute float scaleLoc;
            attribute float popLoc;
            attribute vec3 colorLoc;
            attribute vec2 textureLoc;
            attribute float vidLoc;

            uniform mat4 uCameraMat;
            uniform mat4 uGlyphMat;
            uniform mat4 uBodyMat;

            varying vec3 vColor;
            varying vec2 vUV;
            varying float vVid;
            varying float vZ;

            void main(void) {
                vec4 pos = uBodyMat * vec4(posLoc, 1.0);
                pos.z += popLoc;
                pos = uCameraMat * pos;
                pos.xy += (uGlyphMat * vec4(cornerLoc, 1.0, 1.0)).xy * scaleLoc;

                vColor = colorLoc;
                vUV = textureLoc;
                vVid = vidLoc;
                vZ = pos.z;

                pos.z = clamp(pos.z, 0.0, 1.0);
                gl_Position = pos;
            }
        ';

        fragShader =
            #if !desktop 'precision mediump float;' + #end
            '
            varying vec3 vColor;
            varying vec2 vUV;
            varying float vVid;
            varying float vZ;

            uniform sampler2D uSampler;

            void main(void) {
                vec4 texture = texture2D(uSampler, vUV);
                if (vVid >= 0.3) texture *= -1.0;
                gl_FragColor = vec4(vColor, 1.0) * (texture + vVid) * clamp(2.0 - vZ, 0.0, 1.0);
            }
        ';
    }

    override function connectToShaders():Void {
        posLoc     = program.getAttribLocation('posLoc');
        cornerLoc  = program.getAttribLocation('cornerLoc');
        scaleLoc   = program.getAttribLocation('scaleLoc');
        popLoc     = program.getAttribLocation('popLoc');
        colorLoc   = program.getAttribLocation('colorLoc');
        textureLoc = program.getAttribLocation('textureLoc');
        vidLoc     = program.getAttribLocation('vidLoc');

        uCameraMat = program.getUniformLocation('uCameraMat');
        uGlyphMat = program.getUniformLocation('uGlyphMat');
        uBodyMat = program.getUniformLocation('uBodyMat');
        uSampler = program.getUniformLocation('uSampler');
        // uCrap = program.getUniformLocation('uCrap');
    }

    override public function setGlyphTexture(glyphTexture:GlyphTexture, glyphTransform:Matrix3D):Void {
        super.setGlyphTexture(glyphTexture, glyphTransform);
        programUtil.setProgramConstantsFromMatrix(uGlyphMat, glyphMat); // uGlyphMat contains the character matrix
        programUtil.setTextureAt(uSampler, 0, glyphTexture.texture); // uSampler contains our texture
    }

    override public function setMatrices(cameraMat:Matrix3D, bodyMat:Matrix3D):Void {
        programUtil.setProgramConstantsFromMatrix(uCameraMat, cameraMat); // uCameraMat contains the camera matrix
        programUtil.setProgramConstantsFromMatrix(uBodyMat, bodyMat); // uBodyMat contains the body's matrix
    }

    override public function setSegment(segment:BodySegment):Void {
        programUtil.setVertexBufferAt(posLoc,     segment.shapeBuffer, 0, 3); // posLoc contains x,y,z
        programUtil.setVertexBufferAt(cornerLoc,  segment.shapeBuffer, 3, 2); // cornerLoc contains h,v
        programUtil.setVertexBufferAt(scaleLoc,   segment.shapeBuffer, 5, 1); // scaleLoc contains s
        programUtil.setVertexBufferAt(popLoc,     segment.shapeBuffer, 6, 1); // popLoc contains p
        programUtil.setVertexBufferAt(colorLoc,   segment.colorBuffer, 0, 3); // colorLoc contains r,g,b
        programUtil.setVertexBufferAt(textureLoc, segment.colorBuffer, 3, 2); // textureLoc contains u,v
        programUtil.setVertexBufferAt(vidLoc,     segment.colorBuffer, 5, 1); // vidLoc contains i
    }
}

