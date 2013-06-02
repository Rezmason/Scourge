package net.rezmason.scourge.textview;

import flash.display.BitmapData;
import flash.display.Shape;
import flash.geom.Matrix3D;
import flash.geom.Vector3D;
import flash.geom.Rectangle;
import flash.Vector;

import openfl.gl.GL;
import openfl.gl.GLUniformLocation;

import net.rezmason.scourge.textview.core.Types;
import net.rezmason.scourge.textview.core.*;

import net.rezmason.scourge.textview.utils.UtilitySet;


class HappyPlace {

    var t:Float;

    var bodyMat:Matrix3D;
    var glyphMat:Matrix3D;
    var cameraMat:Matrix3D;

    var program:Program;
    var numIndices:Int;
    var numTriangles:Int;

    var aPos:Int;
    var aCorner:Int;
    var aScale:Int;
    var aPop:Int;
    var aColor:Int;
    var aUV:Int;
    var aVid:Int;
    var uCameraMat:GLUniformLocation;
    var uGlyphMat:GLUniformLocation;
    var uBodyMat:GLUniformLocation;
    var uSampler:GLUniformLocation;

    var shapeBuffer:VertexBuffer;
    var colorBuffer:VertexBuffer;
    var indexBuffer:IndexBuffer;

    var scissorRect:Rectangle;

    var texture:Texture;

    var w:Int;
    var h:Int;
    var utils:UtilitySet;

    var segment:BodySegment;

    function bonk():Void {};

    public function new(utils:UtilitySet, glyphTexture:GlyphTexture):Void {

        this.utils = utils;

        texture = glyphTexture.texture;

        t = 0;

        w = 0;
        h = 0;
        scissorRect = null;

        var vertShader:String =
        '
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
                pos.xy += (uGlyphMat * vec4(aCorner, 1.0, 1.0)).xy * aScale;

                vColor = aColor;
                vUV = aUV;
                vVid = aVid;
                vZ = pos.z;

                pos.z = clamp(pos.z, 0.0, 1.0);
                gl_Position = pos;
            }
        ';

        var fragShader:String =
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

        program = utils.programUtil.createProgram(vertShader, fragShader);

        aPos     = program.getAttribLocation('aPos');
        aCorner  = program.getAttribLocation('aCorner');
        aScale   = program.getAttribLocation('aScale');
        aPop     = program.getAttribLocation('aPop');
        aColor   = program.getAttribLocation('aColor');
        aUV = program.getAttribLocation('aUV');
        aVid     = program.getAttribLocation('aVid');

        uCameraMat = program.getUniformLocation('uCameraMat');
        uGlyphMat = program.getUniformLocation('uGlyphMat');
        uBodyMat = program.getUniformLocation('uBodyMat');
        uSampler = program.getUniformLocation('uSampler');

        var body:Body = new TestBody(1, utils.bufferUtil, glyphTexture, bonk);
        body.update(0);
        segment = body.segments[0];

        var shapeVertices:Array<Float> = [
        //    x,   y,   z,   h, v,   s,   p,
            0.0, 0.0, 0.0,   0, 0,   1,   0,
            0.0, 0.0, 0.0,   0, 1,   1,   0,
            0.0, 0.0, 0.0,   1, 1,   1,   0,
            0.0, 0.0, 0.0,   1, 0,   1,   0,
        ];

        var colorVertices:Array<Float> = [
        //  r, g, b,   u, v,     i,
            1, 0, 0,   0, 0,   0.2,
            1, 0, 0,   0, 1,   0.2,
            1, 0, 0,   1, 1,   0.2,
            1, 0, 0,   1, 0,   0.2,
        ];

        var charUV = glyphTexture.font.getCharCodeUVs('A'.charCodeAt(0));
        var cpv:Int = 6;
        colorVertices[3 + 0 * cpv] = charUV[3].u; colorVertices[4 + 0 * cpv] = charUV[3].v;
        colorVertices[3 + 1 * cpv] = charUV[0].u; colorVertices[4 + 1 * cpv] = charUV[0].v;
        colorVertices[3 + 2 * cpv] = charUV[1].u; colorVertices[4 + 2 * cpv] = charUV[1].v;
        colorVertices[3 + 3 * cpv] = charUV[2].u; colorVertices[4 + 3 * cpv] = charUV[2].v;

        var indices:Array<Int> = [
            0, 1, 2,
            0, 2, 3,
        ];

        /*
        shapeBuffer = utils.bufferUtil.createVertexBuffer(-1, 3 + 2 + 1 + 1);
        shapeBuffer.uploadFromVector(shapeVertices);

        colorBuffer = utils.bufferUtil.createVertexBuffer(-1, 3 + 2 + 1);
        colorBuffer.uploadFromVector(colorVertices);

        indexBuffer = utils.bufferUtil.createIndexBuffer(-1);
        indexBuffer.uploadFromVector(indices);
        */

        shapeBuffer = segment.shapeBuffer;
        colorBuffer = segment.colorBuffer;
        indexBuffer = segment.indexBuffer;

        numIndices = indexBuffer.count;
        numTriangles = Std.int(numIndices / 3);


        cameraMat = makeProjection();
        bodyMat = new Matrix3D();
        glyphMat = new Matrix3D();

        glyphMat.appendTranslation(-0.5, -0.5, 0);
        glyphMat.appendScale(0.04, 0.04, 1);
    }

    function updateTransform():Void {
        t += 0.05;
        bodyMat.identity();
        bodyMat.appendRotation(t * 10, Vector3D.Y_AXIS);
        bodyMat.appendScale(2, 2, 1);
        var gallop:Float = Math.sin(t * 2) * 0.5 + 1.5;
        bodyMat.appendTranslation(0, 0, gallop);
    }

    public function render(w:Int, h:Int):Void {

        updateTransform();

        if (this.w != w || this.h != h) {
            this.w = w;
            this.h = h;
            utils.drawUtil.resize(w, h);
        }

        utils.drawUtil.setScissorRectangle(scissorRect);
        utils.drawUtil.clear(0x0);

        utils.programUtil.setProgram(program);
        utils.programUtil.setBlendFactors(BlendFactor.ONE, BlendFactor.ONE);
        utils.programUtil.setBlending(true);
        utils.programUtil.setDepthTest(false);

        utils.programUtil.setProgramConstantsFromMatrix(uCameraMat, cameraMat);
        utils.programUtil.setProgramConstantsFromMatrix(uBodyMat, bodyMat);
        utils.programUtil.setProgramConstantsFromMatrix(uGlyphMat, glyphMat);

        utils.programUtil.setTextureAt(uSampler, 0, texture);

        utils.programUtil.setVertexBufferAt(aPos,     shapeBuffer, 0, 3); // aPos contains x,y,z
        utils.programUtil.setVertexBufferAt(aCorner,  shapeBuffer, 3, 2); // aCorner contains h,v
        utils.programUtil.setVertexBufferAt(aScale,   shapeBuffer, 5, 1); // aScale contains s
        utils.programUtil.setVertexBufferAt(aPop,     shapeBuffer, 6, 1); // aPop contains p
        utils.programUtil.setVertexBufferAt(aColor,   colorBuffer, 0, 3); // aColor contains r,g,b
        utils.programUtil.setVertexBufferAt(aUV,      colorBuffer, 3, 2); // aUV contains u,v
        utils.programUtil.setVertexBufferAt(aVid,     colorBuffer, 5, 1); // aVid contains i

        utils.drawUtil.drawTriangles(indexBuffer, 0, numTriangles);

        utils.programUtil.setVertexBufferAt(aPos,     null, 0, 3);
        utils.programUtil.setVertexBufferAt(aCorner,  null, 3, 2);
        utils.programUtil.setVertexBufferAt(aScale,   null, 5, 1);
        utils.programUtil.setVertexBufferAt(aPop,     null, 6, 1);
        utils.programUtil.setVertexBufferAt(aColor,   null, 0, 3);
        utils.programUtil.setVertexBufferAt(aUV,      null, 3, 2);
        utils.programUtil.setVertexBufferAt(aVid,     null, 5, 1);

    }

    inline function makeProjection():Matrix3D {
        var mat:Matrix3D = new Matrix3D();
        var rawData:Vector<Float> = mat.rawData;
        rawData[10] =  2;
        rawData[11] =  1;
        rawData[14] = -2;
        rawData[15] =  0;
        mat.rawData = rawData;
        return mat;
    }
}
