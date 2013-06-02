package net.rezmason.scourge.textview;

import flash.display.BitmapData;
import flash.display.Shape;
import flash.geom.Matrix3D;
import flash.geom.Rectangle;
import openfl.gl.GL;
import openfl.gl.GLUniformLocation;

import net.rezmason.scourge.textview.core.Types;
import net.rezmason.scourge.textview.core.*;

import net.rezmason.scourge.textview.utils.UtilitySet;


class NMEDemo {

    var t:Float;

    inline static var SHAPE_FLOATS_PER_VERTEX:Int = 2;
    inline static var TEXTURE_FLOATS_PER_VERTEX:Int = 2;
    inline static var COLOR_FLOATS_PER_VERTEX:Int = 4;

    var transform:Matrix3D;
    var baseTransform:Matrix3D;
    var projection:Matrix3D;

    var program:Program;
    var numIndices:Int;
    var numTriangles:Int;

    var posLocation:Int;
    var texLocation:Int;
    var colorLocation:Int;
    var projectionLocation:GLUniformLocation;
    var transformLocation:GLUniformLocation;
    var samplerLocation:GLUniformLocation;

    var posBuffer:VertexBuffer;
    // var texBuffer:VertexBuffer;
    var colorBuffer:VertexBuffer;
    var indexBuffer:IndexBuffer;

    var scissorRect:Rectangle;

    var texture:Texture;

    var w:Int;
    var h:Int;
    var utils:UtilitySet;

    function bonk():Void {};

    public function new(utils:UtilitySet, glyphTexture:GlyphTexture):Void {

        this.utils = utils;

        var body:Body = new TestBody(1, utils.bufferUtil, glyphTexture, bonk);

        texture = glyphTexture.texture;

        t = 0;

        w = 0;
        h = 0;
        scissorRect = null;

        var posName:String = 'aPos';
        var texName:String = 'aTexCoord';
        var colorName:String = 'aVertexColor';
        var samplerName:String = 'uSampler';
        var projectionName:String = 'projectionLocation';
        var transformName:String = 'transformLocation';

        var vertShader:String =
        '
        attribute vec2 $posName;
        attribute vec4 $colorName;
        attribute vec2 $texName;

        uniform mat4 $projectionName;
        uniform mat4 $transformName;

        varying vec4 vColor;
        varying vec2 vTexCoord;

        void main(void) {
            gl_Position = $projectionName * $transformName * vec4($posName, 0.0, 1.0);
            vColor = $colorName;
            vTexCoord = $texName;
        }
        ';

        var fragShader:String =
        #if !desktop 'precision mediump float;' + #end
        '
        varying vec4 vColor;
        varying vec2 vTexCoord;

        uniform sampler2D $samplerName;

        void main(void) {
            gl_FragColor = vColor * (1.0 - texture2D($samplerName, vTexCoord));
        }
        ';

        program = utils.programUtil.createProgram(vertShader, fragShader);

        posLocation = program.getAttribLocation(posName);
        texLocation = program.getAttribLocation(texName);
        colorLocation = program.getAttribLocation(colorName);
        samplerLocation = program.getUniformLocation(samplerName);
        projectionLocation = program.getUniformLocation(projectionName);
        transformLocation = program.getUniformLocation(transformName);

        var vertPositions:Array<Float> = [
            0, -1, -1,
            0, -1,  1,
            0,  1,  1,
            0,  1, -1,
        ];

        var colors:Array<Float> = [
        //    r,   g,   b,   a,   u, v,
            2.0, 0.0, 0.0, 1.0,   0, 0,
            0.6, 1.2, 0.0, 1.0,   0, 1,
            0.0, 2.0, 2.0, 1.0,   1, 1,
            0.6, 0.0, 1.2, 1.0,   1, 0,
        ];

        var indices:Array<Int> = [
            0, 1, 2,
            0, 2, 3,
        ];

        projection = new Matrix3D();
        transform = new Matrix3D();

        baseTransform = new Matrix3D();
        baseTransform.appendScale(1, -1, 1);

        // texture = utils.textureUtil.createTexture(createTextureBD());

        posBuffer = utils.bufferUtil.createVertexBuffer(-1, SHAPE_FLOATS_PER_VERTEX + 1);
        posBuffer.uploadFromVector(vertPositions);

        // texBuffer = utils.bufferUtil.createVertexBuffer(-1, TEXTURE_FLOATS_PER_VERTEX);
        // texBuffer.uploadFromVector(texCoords);

        colorBuffer = utils.bufferUtil.createVertexBuffer(-1, COLOR_FLOATS_PER_VERTEX + TEXTURE_FLOATS_PER_VERTEX);
        colorBuffer.uploadFromVector(colors);

        indexBuffer = utils.bufferUtil.createIndexBuffer(-1);
        indexBuffer.uploadFromVector(indices);


        numIndices = indexBuffer.count;
        numTriangles = Std.int(numIndices / 3);
    }

    function updateTransform():Void {
        t += 0.05;
        transform.identity();
        transform.append(baseTransform);
        var scale:Float = Math.sin(t * 2) * 0.2 + 0.8;
        transform.appendScale(scale, scale, 1);
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

        utils.programUtil.setProgramConstantsFromMatrix(projectionLocation, projection);
        utils.programUtil.setProgramConstantsFromMatrix(transformLocation, transform);

        utils.programUtil.setTextureAt(samplerLocation, 0, texture);

        utils.programUtil.setVertexBufferAt(posLocation, posBuffer, 1, SHAPE_FLOATS_PER_VERTEX);
        utils.programUtil.setVertexBufferAt(colorLocation, colorBuffer, 0, COLOR_FLOATS_PER_VERTEX);
        utils.programUtil.setVertexBufferAt(texLocation, colorBuffer, COLOR_FLOATS_PER_VERTEX, TEXTURE_FLOATS_PER_VERTEX);

        utils.drawUtil.drawTriangles(indexBuffer, 0, numTriangles);

        utils.programUtil.setVertexBufferAt(posLocation, null);
        utils.programUtil.setVertexBufferAt(colorLocation, null);
        utils.programUtil.setVertexBufferAt(texLocation, null);
    }
}
