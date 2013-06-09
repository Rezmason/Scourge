package net.rezmason.scourge.textview.rendermethods;

import flash.geom.Matrix3D;

import net.rezmason.scourge.textview.core.BodySegment;
import net.rezmason.scourge.textview.core.GlyphTexture;
import net.rezmason.scourge.textview.core.RenderMethod;
import net.rezmason.gl.BlendFactor;
import net.rezmason.gl.Types;

class PrettyMethod extends RenderMethod {

    var aPos:AttribsLocation;
    var aCorner:AttribsLocation;
    var aScale:AttribsLocation;
    var aPop:AttribsLocation;
    var aColor:AttribsLocation;
    var aUV:AttribsLocation;
    var aVid:AttribsLocation;
    var uSampler:UniformLocation;
    var uGlyphMat:UniformLocation;
    var uCameraMat:UniformLocation;
    var uBodyMat:UniformLocation;

    override public function activate():Void {
        programUtil.setProgram(program);
        programUtil.setBlendFactors(BlendFactor.ONE, BlendFactor.ONE);
        programUtil.setDepthTest(false);
    }

    override public function deactivate():Void {
        programUtil.setVertexBufferAt(program, aPos,    null, 0, 3);
        programUtil.setVertexBufferAt(program, aCorner, null, 3, 2);
        programUtil.setVertexBufferAt(program, aScale,  null, 5, 1);
        programUtil.setVertexBufferAt(program, aPop,    null, 6, 1);
        programUtil.setVertexBufferAt(program, aColor,  null, 0, 3);
        programUtil.setVertexBufferAt(program, aUV,     null, 3, 2);
        programUtil.setVertexBufferAt(program, aVid,    null, 5, 1);
    }

    override function composeShaders():Void {
        vertShader = '
            attribute vec3 aPos;
            attribute vec2 aCorner;
            attribute float aScale;
            attribute float aPop;
            attribute vec3 aColor;
            attribute vec2 aUV;
            attribute float aVid;

            uniform mat4 uCameraMat;
            uniform mat4 uGlyphMat;
            uniform mat4 uBodyMat;

            varying vec3 vColor;
            varying vec2 vUV;
            varying float vVid;
            varying float vZ;

            void main(void) {
                vec4 pos = uBodyMat * vec4(aPos, 1.0);
                pos.z += aPop;
                pos = uCameraMat * pos;
                pos.xy += ((uGlyphMat * vec4(aCorner, 1.0, 1.0)).xy) * aScale;

                vColor = aColor;
                vUV = aUV;
                vVid = aVid;
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
                vec3 texture = texture2D(uSampler, vUV).rgb;
                if (vVid >= 0.3) texture *= -1.0;
                gl_FragColor = vec4(vColor * (texture + vVid) * clamp(2.0 - vZ, 0.0, 1.0), 1.0);
            }
        ';
    }

    override function connectToShaders():Void {

        aPos    = programUtil.getAttribsLocation(program, 'aPos'   );
        aCorner = programUtil.getAttribsLocation(program, 'aCorner');
        aScale  = programUtil.getAttribsLocation(program, 'aScale' );
        aPop    = programUtil.getAttribsLocation(program, 'aPop'   );
        aColor  = programUtil.getAttribsLocation(program, 'aColor' );
        aUV     = programUtil.getAttribsLocation(program, 'aUV'    );
        aVid    = programUtil.getAttribsLocation(program, 'aVid'   );

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
        programUtil.setVertexBufferAt(program, aPos,    segment.shapeBuffer, 0, 3); // aPos contains x,y,z
        programUtil.setVertexBufferAt(program, aCorner, segment.shapeBuffer, 3, 2); // aCorner contains h,v
        programUtil.setVertexBufferAt(program, aScale,  segment.shapeBuffer, 5, 1); // aScale contains s
        programUtil.setVertexBufferAt(program, aPop,    segment.shapeBuffer, 6, 1); // aPop contains p
        programUtil.setVertexBufferAt(program, aColor,  segment.colorBuffer, 0, 3); // aColor contains r,g,b
        programUtil.setVertexBufferAt(program, aUV,     segment.colorBuffer, 3, 2); // aUV contains u,v
        programUtil.setVertexBufferAt(program, aVid,    segment.colorBuffer, 5, 1); // aVid contains i
    }
}

