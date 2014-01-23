package net.rezmason.scourge.textview;

import flash.Vector;
import flash.display.Stage;
import flash.geom.Matrix3D;
import flash.geom.Vector3D;

import net.rezmason.gl.utils.*;
import net.rezmason.gl.*;
import net.rezmason.gl.Data;
import net.rezmason.scourge.textview.core.*;
import net.rezmason.utils.FlatFont;

class Lab {

    static var fragShader:String = #if !desktop 'precision mediump float;' + #end '
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

    static var vertShader:String = '
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

    var uBodyMat:UniformLocation;
    var uCameraMat:UniformLocation;
    var uGlyphMat:UniformLocation;

    var uSampler:UniformLocation;

    var aPos:AttribsLocation;
    var aCorner:AttribsLocation;
    var aScale:AttribsLocation;
    var aPop:AttribsLocation;
    var aColor:AttribsLocation;
    var aUV:AttribsLocation;
    var aVid:AttribsLocation;

    var glyphTexture:GlyphTexture;
    var program:Program;

    var body:Body;

    var numTriangles:Int;
    var mainOutputBuffer:OutputBuffer;
    var secondBuffer:OutputBuffer;

    var shapeBuffer:VertexBuffer;
    var colorBuffer:VertexBuffer;
    var indexBuffer:IndexBuffer;

    var utils:UtilitySet;
    var stage:Stage;

    var width:Int;
    var height:Int;

    var t:Float;
    var segment:BodySegment;

    var data:ReadbackData;

    public function new(utils:UtilitySet, stage:Stage, fonts:Map<String, FlatFont>):Void {
        this.utils = utils;
        this.stage = stage;
        this.glyphTexture = new GlyphTexture(utils.textureUtil, fonts['full']);

        width = stage.stageWidth;
        height = stage.stageHeight;

        mainOutputBuffer = utils.drawUtil.getMainOutputBuffer();
        mainOutputBuffer.resize(width, height);

        secondBuffer = utils.drawUtil.createOutputBuffer();
        secondBuffer.resize(width, height);

        data = utils.drawUtil.createReadbackData(width * height * 4);

        // Create program

        utils.programUtil.loadProgram(vertShader, fragShader, onProgramLoaded);

        // Create geometry

        body = new TestBody(utils.bufferUtil, glyphTexture, bonk, 10);
        body.update(0);
        segment = body.segments[0];

        var scale:Float = 0.1;
        body.glyphTransform.identity();
        body.glyphTransform.append(glyphTexture.matrix);
        body.glyphTransform.appendScale(scale, scale, 1);

        /*
        var shapeVertices:Vector<Float> = Vector.ofArray(cast [
        //  x, y, z,   h, v,   s,   p,
            0, 0, 0,   0, 0,   1,   0,
            0, 0, 0,   0, 1,   1,   0,
            0, 0, 0,   1, 1,   1,   0,
            0, 0, 0,   1, 0,   1,   0,
        ]);

        var colorVertices:Vector<Float> = Vector.ofArray(cast [
        //  r, g, b,   u, v,     i,
            1, 0, 0,   0, 0,   0.2,
            1, 0, 0,   0, 1,   0.2,
            1, 0, 0,   1, 1,   0.2,
            1, 0, 0,   1, 0,   0.2,
        ]);

        var charUV = glyphTexture.font.getCharCodeUVs('A'.charCodeAt(0));
        var cpv:Int = 6;
        colorVertices[3 + 0 * cpv] = charUV[3].u; colorVertices[4 + 0 * cpv] = charUV[3].v;
        colorVertices[3 + 1 * cpv] = charUV[0].u; colorVertices[4 + 1 * cpv] = charUV[0].v;
        colorVertices[3 + 2 * cpv] = charUV[1].u; colorVertices[4 + 2 * cpv] = charUV[1].v;
        colorVertices[3 + 3 * cpv] = charUV[2].u; colorVertices[4 + 3 * cpv] = charUV[2].v;

        var indices:Vector<UInt> = Vector.ofArray(cast [
            0, 1, 2,
            0, 2, 3,
        ]);

        var numIndices:Int = 6;
        var numVertices:Int = 4;
        numTriangles = 2;

        shapeBuffer = utils.bufferUtil.createVertexBuffer(numVertices, 3 + 2 + 2);
        shapeBuffer.uploadFromVector(shapeVertices, 0, numVertices);

        colorBuffer = utils.bufferUtil.createVertexBuffer(numVertices, 3 + 2 + 1);
        colorBuffer.uploadFromVector(colorVertices, 0, numVertices);

        indexBuffer = utils.bufferUtil.createIndexBuffer(numIndices);
        indexBuffer.uploadFromVector(indices, 0, numIndices);
        */

        shapeBuffer = segment.shapeBuffer;
        colorBuffer = segment.colorBuffer;
        indexBuffer = segment.indexBuffer;

        numTriangles = Std.int(segment.numGlyphs * 2);

        t = 0;
    }

    function onProgramLoaded(program:Program):Void {
        this.program = program;

        // Connect to shader

        uBodyMat = utils.programUtil.getUniformLocation(program, 'uBodyMat');
        uCameraMat = utils.programUtil.getUniformLocation(program, 'uCameraMat');
        uGlyphMat = utils.programUtil.getUniformLocation(program, 'uGlyphMat');

        uSampler = utils.programUtil.getUniformLocation(program, 'uSampler');

        aPos = utils.programUtil.getAttribsLocation(program, 'aPos');
        aCorner = utils.programUtil.getAttribsLocation(program, 'aCorner');
        aScale = utils.programUtil.getAttribsLocation(program, 'aScale');
        aPop = utils.programUtil.getAttribsLocation(program, 'aPop');
        aColor = utils.programUtil.getAttribsLocation(program, 'aColor');
        aUV = utils.programUtil.getAttribsLocation(program, 'aUV');
        aVid = utils.programUtil.getAttribsLocation(program, 'aVid');

        utils.drawUtil.addRenderCall(onRender);
    }

    function bonk():Void {

    }

    function update():Void {
        /*
        t += 0.1;
        var scale:Float = Math.sin(t) * 0.25 + 1;

        scale *= 0.03;

        body.glyphTransform.identity();
        body.glyphTransform.append(glyphTexture.matrix);
        body.glyphTransform.appendScale(scale, scale, 1);
        */

        body.update(0.1);
    }

    function onRender(w:Int, h:Int):Void {

        if (program == null) return;

        update();

        utils.programUtil.setProgram(program);
        utils.programUtil.setBlendFactors(BlendFactor.ONE, BlendFactor.ONE);
        utils.programUtil.setDepthTest(false);

        utils.programUtil.setProgramConstantsFromMatrix(program, uBodyMat, body.transform); // uBodyMat contains the body's matrix
        utils.programUtil.setProgramConstantsFromMatrix(program, uCameraMat, body.camera); // uCameraMat contains the camera matrix
        utils.programUtil.setProgramConstantsFromMatrix(program, uGlyphMat, body.glyphTransform); // uGlyphMat contains the character matrix

        utils.programUtil.setTextureAt(program, uSampler, glyphTexture.texture); // uSampler contains our texture

        utils.programUtil.setVertexBufferAt(program, aPos,     shapeBuffer, 0, 3); // aPos contains x,y,z
        utils.programUtil.setVertexBufferAt(program, aCorner,  shapeBuffer, 3, 2); // aCorner contains h,v
        utils.programUtil.setVertexBufferAt(program, aScale,   shapeBuffer, 5, 1); // aScale contains s
        utils.programUtil.setVertexBufferAt(program, aPop,     shapeBuffer, 6, 1); // aPop contains p
        utils.programUtil.setVertexBufferAt(program, aColor,   colorBuffer, 0, 3); // aColor contains r,g,b
        utils.programUtil.setVertexBufferAt(program, aUV,      colorBuffer, 3, 2); // aUV contains u,v
        utils.programUtil.setVertexBufferAt(program, aVid,     colorBuffer, 5, 1); // aVid contains i

        //*
        utils.drawUtil.setOutputBuffer(secondBuffer);
        utils.drawUtil.clear(0xFF000000);
        utils.drawUtil.drawTriangles(indexBuffer, 0, numTriangles);
        utils.drawUtil.finishOutputBuffer(secondBuffer);

        utils.drawUtil.readBack(secondBuffer, width, height, data);

        var whiteCount:Int = 0;

        for (i in 0...width * height) {
            var pixel:Int = (data[i * 4 + 3] << 24) | (data[i * 4 + 1] << 16) | (data[i * 4 + 1] << 8) | (data[i * 4 + 2] << 0);
            if (pixel == 0xFFFFFFFF) whiteCount++;
        }

        trace(whiteCount / (width * height));
        /**/

        //*
        utils.drawUtil.setOutputBuffer(mainOutputBuffer);
        utils.drawUtil.clear(0xFF000000);
        utils.drawUtil.drawTriangles(indexBuffer, 0, numTriangles);
        utils.drawUtil.finishOutputBuffer(mainOutputBuffer);
        /**/
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
