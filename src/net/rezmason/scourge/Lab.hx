package net.rezmason.scourge;

import openfl.Assets.*;
import flash.Vector;
import flash.display.Stage;
import flash.geom.Matrix3D;
import flash.geom.Vector3D;

import net.rezmason.gl.utils.*;
import net.rezmason.gl.*;
import net.rezmason.gl.Data;
import net.rezmason.scourge.textview.*;
import net.rezmason.scourge.textview.core.*;
import net.rezmason.scourge.textview.demo.*;
import net.rezmason.utils.display.FlatFont;

class Lab {

    var aPos:AttribsLocation;
    var aCorner:AttribsLocation;
    var aScale:AttribsLocation;
    var aUV:AttribsLocation;
    
    var uSampler:UniformLocation;
    var uParams:UniformLocation;
    var uCameraMat:UniformLocation;
    var uBodyMat:UniformLocation;

    var glyphTexture:GlyphTexture;
    var program:Program;

    var bodyTransform:Matrix3D;
    var cameraTransform:Matrix3D;

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

    public function new(utils:UtilitySet, stage:Stage):Void {
        this.utils = utils;
        this.stage = stage;

        var font:FlatFont = new FlatFont(getBitmapData('metaballs/metaball.png'), '{}');
        this.glyphTexture = new GlyphTexture(utils.textureUtil, font);

        bodyTransform = new Matrix3D();
        cameraTransform = makeProjection();

        width = stage.stageWidth;
        height = stage.stageHeight;

        mainOutputBuffer = utils.drawUtil.getMainOutputBuffer();
        mainOutputBuffer.resize(width, height);

        secondBuffer = utils.drawUtil.createOutputBuffer();
        secondBuffer.resize(width, height);

        // Create program

        var vertShader = '
            attribute vec3 aPos;
            attribute vec2 aCorner;
            attribute float aScale;
            attribute vec2 aUV;

            uniform mat4 uCameraMat;
            uniform mat4 uBodyMat;

            varying vec2 vUV;

            void main(void) {
                vec4 pos = uBodyMat * vec4(aPos, 1.0);
                pos = uCameraMat * pos;
                pos.xy += ((vec4(aCorner.x, aCorner.y, 1.0, 1.0)).xy) * aScale;

                vUV = aUV;

                pos.z = clamp(pos.z, 0.0, 1.0);
                gl_Position = pos;
            }
        ';
        var fragShader = '
            varying vec2 vUV;

            uniform sampler2D uSampler;
            uniform vec4 uParams;

            void main(void) {
                gl_FragColor = texture2D(uSampler, vUV);
            }
        ';

        utils.programUtil.loadProgram(vertShader, fragShader, onProgramLoaded);

        // Create geometry

        var body:Body = new GlyphBody(utils.bufferUtil, glyphTexture);
        body.adjustLayout(stage.stageWidth, stage.stageHeight);
        body.update(0);

        cameraTransform = body.camera;

        trace(cameraTransform.rawData);

        var spv:Int = 3 + 2 + 1;
        var cpv:Int = 2;

        var shapeVertices:VertexArray = arrToVertexArray([
        //  x,y,z, h, v,s,
            0,0,0,-1,-1,0.1,
            0,0,0,-1, 1,0.1,
            0,0,0, 1, 1,0.1,
            0,0,0, 1,-1,0.1,
        ], spv);

        var colorVertices:VertexArray = arrToVertexArray([
        //  u,v,
            0,1,
            0,0,
            1,0,
            1,1,
        ], cpv);

        var indices:IndexArray = arrToIndexArray([
            0, 1, 2,
            0, 2, 3,
        ]);

        var numIndices:Int = 6;
        var numVertices:Int = 4;
        numTriangles = 2;

        shapeBuffer = utils.bufferUtil.createVertexBuffer(numVertices, spv);
        shapeBuffer.uploadFromVector(shapeVertices, 0, numVertices);
        colorBuffer = utils.bufferUtil.createVertexBuffer(numVertices, cpv);
        colorBuffer.uploadFromVector(colorVertices, 0, numVertices);
        indexBuffer = utils.bufferUtil.createIndexBuffer(numIndices);
        indexBuffer.uploadFromVector(indices, 0, numIndices);

        t = 0;
    }

    function onProgramLoaded(program:Program):Void {
        this.program = program;
        utils.programUtil.setFourProgramConstants(this.program, uParams, [0, 0, 0, 0]);

        // Connect to shader

        aPos     = utils.programUtil.getAttribsLocation(program, 'aPos'    );
        aCorner  = utils.programUtil.getAttribsLocation(program, 'aCorner' );
        aScale   = utils.programUtil.getAttribsLocation(program, 'aScale');
        aUV      = utils.programUtil.getAttribsLocation(program, 'aUV'     );
        
        uSampler   = utils.programUtil.getUniformLocation(program, 'uSampler'  );
        uParams    = utils.programUtil.getUniformLocation(program, 'uParams');
        uCameraMat = utils.programUtil.getUniformLocation(program, 'uCameraMat');
        uBodyMat   = utils.programUtil.getUniformLocation(program, 'uBodyMat'  );

        utils.drawUtil.addRenderCall(onRender);
    }

    function update():Void {
        t += 0.1;
        var nudgeX:Float = Math.cos(t) * 0.0625;
        var nudgeY:Float = Math.sin(t) * 0.0625;

        bodyTransform.identity();
        bodyTransform.appendTranslation(nudgeX, nudgeY, 0);
    }

    function onRender(w:Int, h:Int):Void {

        if (program == null) return;

        update();

        utils.programUtil.setProgram(program);
        utils.programUtil.setBlendFactors(BlendFactor.ONE, BlendFactor.ONE);
        utils.programUtil.setDepthTest(false);

        utils.programUtil.setProgramConstantsFromMatrix(program, uBodyMat, bodyTransform); // uBodyMat contains the body's matrix
        utils.programUtil.setProgramConstantsFromMatrix(program, uCameraMat, cameraTransform); // uCameraMat contains the camera matrix
        
        utils.programUtil.setTextureAt(program, uSampler, glyphTexture.texture); // uSampler contains our texture

        utils.programUtil.setVertexBufferAt(program, aPos,     shapeBuffer, 0, 3); // aPos contains x,y,z
        utils.programUtil.setVertexBufferAt(program, aCorner,  shapeBuffer, 3, 2); // aCorner contains h,v
        utils.programUtil.setVertexBufferAt(program, aScale,   shapeBuffer, 5, 1); // aScale contains s
        utils.programUtil.setVertexBufferAt(program, aUV,      colorBuffer, 0, 2); // aUV contains u,v

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

    inline function arrToVertexArray(arr:Array<Float>, num):VertexArray {
        var va:VertexArray = new VertexArray(arr.length * num);
        for (i in 0...arr.length) va[i] = arr[i];
        return va;
    }

    inline function arrToIndexArray(arr:Array<UInt>):IndexArray {
        var ia:IndexArray = new IndexArray(arr.length);
        for (i in 0...arr.length) ia[i] = arr[i];
        return ia;
    }
}
