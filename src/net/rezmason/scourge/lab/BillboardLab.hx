package net.rezmason.scourge.lab;

import lime.math.Matrix4;
import lime.math.Vector4;
import lime.utils.Float32Array;
import net.rezmason.gl.*;
import net.rezmason.math.Vec4;

class BillboardLab extends Lab {

    inline static var SOLID_FpV:Int = 3 + 3; // floats per vertex
    inline static var CUBE_NUM_VERTICES = 8;
    inline static var CUBE_NUM_TRIANGLES = 12;
    inline static var PLANE_NUM_VERTICES = 4;
    inline static var PLANE_NUM_TRIANGLES = 2;
    var solidProgram:Program;
    var cubeVertexBuffer:VertexBuffer;
    var cubeIndexBuffer:IndexBuffer;
    var planeVertexBuffer:VertexBuffer;
    var planeIndexBuffer:IndexBuffer;

    inline static var BILLBOARD_FpV:Int = 3 + 2 + 1; // floats per vertex
    inline static var BILLBOARD_NUM_VERTICES_PER_BILLBOARD = 4;
    inline static var BILLBOARD_NUM_TRIANGLES_PER_BILLBOARD = 2;
    inline static var NUM_BILLBOARDS = 8;

    var billboardProgram:Program;
    var billboardVertexBuffer:VertexBuffer;
    var billboardIndexBuffer:IndexBuffer;

    var cubeTilt:Matrix4;
    var cubeTransform:Matrix4;
    var planeTransform:Matrix4;
    var sceneTransform:Matrix4;
    var fullTransform:Matrix4;
    var perspectiveTransform:Matrix4;
    var cameraTransform:Matrix4;

    var time:Float = 0;
    
    function perspectiveRH(width, height, zNear, zFar) {
        var mat = new Matrix4();

        mat.set(0, 2 * zNear / width);
        mat.set(5, 2 * zNear / height);
        mat.set(10, zFar / (zNear - zFar));
        mat.set(11, -1);
        mat.set(14, zNear * zFar / (zNear - zFar));

        return mat;
    }

    override function init() {

        cubeTilt = new Matrix4();
        cubeTilt.appendRotation(135, Vector4.Y_AXIS);
        cubeTilt.appendRotation(Math.acos(1 / Math.sqrt(3)) * 180 / Math.PI, Vector4.X_AXIS);
        cubeTransform = new Matrix4();
        planeTransform = new Matrix4();
        sceneTransform = new Matrix4();
        sceneTransform.appendTranslation(0, 0, -3);
        fullTransform = new Matrix4();
        cameraTransform = new Matrix4();
        perspectiveTransform = perspectiveRH(1, 1, 1, 10);

        makeSolids();
        makeBillboards();
    }

    function makeSolids() {
        var vertShader = '
            attribute vec3 aPos;
            attribute vec3 aColor;
            uniform mat4 uBodyMat;
            uniform mat4 uCameraMat;
            uniform mat4 uPerspectiveMat;
            varying vec4 vColor;
            void main(void) {
                vColor = vec4(aColor, 1.0);
                gl_Position = uPerspectiveMat * uCameraMat * uBodyMat * vec4(aPos, 1.0);
            }
        ';
        var fragShader = '
            varying vec4 vColor;

            void main(void) {
                gl_FragColor = vColor;
            }
        ';

        // cube

        cubeVertexBuffer = new VertexBuffer(CUBE_NUM_VERTICES, SOLID_FpV);
        var cubeVert = [
        //   X   Y   Z  
             1, -1, -1,  0.1, 0.0, 0.0,
             1, -1,  1,  0.1, 0.0, 0.1,
             1,  1, -1,  0.1, 0.1, 0.0,
             1,  1,  1,  0.1, 0.1, 0.1,
            -1, -1, -1,  0.0, 0.0, 0.0,
            -1, -1,  1,  0.0, 0.0, 0.1,
            -1,  1, -1,  0.0, 0.1, 0.0,
            -1,  1,  1,  0.0, 0.1, 0.1,
        ];

        for (ike in 0...cubeVertexBuffer.numVertices * SOLID_FpV) cubeVertexBuffer.mod(ike, cubeVert[ike]);
        cubeVertexBuffer.upload();

        cubeIndexBuffer = new IndexBuffer(CUBE_NUM_TRIANGLES * 3);
        var cubeInd = [
            0, 2, 3,   3, 1, 0,
            0, 4, 6,   6, 2, 0,
            0, 1, 5,   5, 4, 0,
            7, 6, 4,   4, 5, 7,
            7, 5, 1,   1, 3, 7,
            7, 3, 2,   2, 6, 7,
        ];
        for (ike in 0...cubeIndexBuffer.numIndices) cubeIndexBuffer.mod(ike, cubeInd[ike]);
        cubeIndexBuffer.upload();

        // plane

        planeVertexBuffer = new VertexBuffer(PLANE_NUM_VERTICES, SOLID_FpV);
        var planeVert = [
        //   X   Y   Z  
             1,  0,  1,  0.4, 0.0, 0.0,
             1,  0, -1,  0.2, 0.2, 0.0,
            -1,  0, -1,  0.0, 0.4, 0.0,
            -1,  0,  1,  0.0, 0.0, 0.4,
        ];

        for (ike in 0...planeVertexBuffer.numVertices * SOLID_FpV) planeVertexBuffer.mod(ike, planeVert[ike]);
        planeVertexBuffer.upload();

        planeIndexBuffer = new IndexBuffer(PLANE_NUM_TRIANGLES * 3);
        var planeInd = [
            0, 1, 2, 0, 2, 3,
        ];
        for (ike in 0...planeIndexBuffer.numIndices) planeIndexBuffer.mod(ike, planeInd[ike]);
        planeIndexBuffer.upload();

        solidProgram = new Program(vertShader, fragShader, []);
    }

    function makeBillboards() {
        var vertShader = '
            attribute vec3 aPos;
            attribute vec2 aCorner;
            attribute float aScale;
            uniform mat4 uBodyMat;
            uniform mat4 uCameraMat;
            uniform mat4 uPerspectiveMat;
            uniform float uBodyScreenScale;
            varying vec4 vColor;
            void main(void) {
                vColor = vec4((aCorner + 1.0) * 0.5, 0.5, 1.0);
                vec4 position = uPerspectiveMat * uCameraMat * uBodyMat * vec4(aPos, 1.0);

                position.xy += aCorner * aScale * uBodyScreenScale;
                gl_Position = position;
            }
        ';
        var fragShader = '
            varying vec4 vColor;

            void main(void) {
                gl_FragColor = vColor;
            }
        ';

        billboardVertexBuffer = new VertexBuffer(BILLBOARD_NUM_VERTICES_PER_BILLBOARD * NUM_BILLBOARDS, BILLBOARD_FpV);
        var billboardPositions:Array<Float> = [
             1, -1, -1,
             1, -1,  1,
             1,  1, -1,
             1,  1,  1,
            -1, -1, -1,
            -1, -1,  1,
            -1,  1, -1,
            -1,  1,  1,
        ];
        var billboardCorners:Array<Float> = [
            -1,  0,
             0, -1,
             1,  0,
             0,  1,
        ];
        var billboardScales:Array<Float> = [0.2];
        var vert:Array<Float> = [for (ike in 0...billboardVertexBuffer.numVertices * BILLBOARD_FpV) 0];

        fillDown(billboardPositions, vert, BILLBOARD_FpV, 0, 3, BILLBOARD_NUM_VERTICES_PER_BILLBOARD);
        fillDown(billboardCorners, vert, BILLBOARD_FpV, 3, 2);
        fillDown(billboardScales, vert, BILLBOARD_FpV, 5, 1);
        
        for (ike in 0...billboardVertexBuffer.numVertices * BILLBOARD_FpV) billboardVertexBuffer.mod(ike, vert[ike]);
        billboardVertexBuffer.upload();

        billboardIndexBuffer = new IndexBuffer(BILLBOARD_NUM_TRIANGLES_PER_BILLBOARD * NUM_BILLBOARDS * 3);
        var billboardIndices = [
            0, 1, 2,
            0, 2, 3,
        ];
        var ind = [
            for (ike in 0...NUM_BILLBOARDS) 
                for (index in billboardIndices) 
                    ike * BILLBOARD_NUM_VERTICES_PER_BILLBOARD + index
        ];
        for (ike in 0...billboardIndexBuffer.numIndices) billboardIndexBuffer.mod(ike, ind[ike]);
        billboardIndexBuffer.upload();

        billboardProgram = new Program(vertShader, fragShader, []);
    }

    function fillDown(src:Array<Float>, dst:Array<Float>, span:UInt, elementOffset:UInt, numElements:UInt, repeat:UInt = 0) {
        if (repeat == 0) repeat = 1;
        var dstOffsets = [for (ike in 0...Std.int(Math.ceil(dst.length /        span))) 
            ike * span
        ];
        var srcOffsets = [for (ike in 0...Std.int(Math.ceil(src.length / numElements))) 
            for (jen in 0...repeat) ike * numElements
        ];

        if (srcOffsets.length == 0) throw 'FUCK';
        while (srcOffsets.length < dstOffsets.length) srcOffsets = srcOffsets.concat(srcOffsets);
        for (ike in 0...dstOffsets.length) {
            var srcOffset = srcOffsets[ike];
            var dstOffset = dstOffsets[ike];
            for (jen in 0...numElements) dst[dstOffset + elementOffset + jen] = src[srcOffset + jen];
        }
    }

    override function update():Void {
        time += 0.01;

        // Body's scale is oscillating,
        var cubeScale = Math.sin(time * 3) * 0.3 + 0.7;
        cubeTransform.identity();
        cubeTransform.appendScale(cubeScale, cubeScale, cubeScale);

        planeTransform.identity();
        planeTransform.appendScale(2, 2, 2);
        planeTransform.appendTranslation(0, -2, 0);

        // Scene's Y is oscillating,
        sceneTransform.identity();
        sceneTransform.appendTranslation(0, Math.sin(time * 2) * 0.1, 0);

        // Camera's rotation-Y is oscillating
        var cameraScale = Math.sin(time * 4) * 0.3 + 0.7;
        cameraTransform.identity();
        cameraTransform.appendRotation(50 * time, Vector4.Y_AXIS);
        cameraTransform.appendScale(cameraScale, cameraScale, cameraScale);
        cameraTransform.appendTranslation(0, 0, -3);
    }

    override function draw():Void {
        
        // solid
        
        solidProgram.use();
        solidProgram.setBlendFactors(BlendFactor.ONE, BlendFactor.ZERO);
        solidProgram.setDepthTest(true);
        solidProgram.setFaceCulling(BACK);

        solidProgram.setRenderTarget(renderTarget);
        solidProgram.clear(new Vec4(0, 0, 0, 1));

        solidProgram.setMatrix4('uCameraMat', cameraTransform);
        solidProgram.setMatrix4('uPerspectiveMat', perspectiveTransform);

        fullTransform.identity();
        fullTransform.append(cubeTilt);
        fullTransform.append(cubeTransform);
        fullTransform.append(sceneTransform);
        solidProgram.setMatrix4('uBodyMat', fullTransform);
        solidProgram.setVertexBuffer('aPos',     cubeVertexBuffer, 0, 3);
        solidProgram.setVertexBuffer('aColor',   cubeVertexBuffer, 3, 3);
        solidProgram.draw(cubeIndexBuffer, 0, CUBE_NUM_TRIANGLES);
        solidProgram.setVertexBuffer('aPos', null, 0, 3);
        solidProgram.setVertexBuffer('aColor', null, 3, 3);

        fullTransform.identity();
        fullTransform.append(planeTransform);
        fullTransform.append(sceneTransform);
        solidProgram.setMatrix4('uBodyMat', fullTransform);
        solidProgram.setVertexBuffer('aPos',     planeVertexBuffer, 0, 3);
        solidProgram.setVertexBuffer('aColor',   planeVertexBuffer, 3, 3);
        solidProgram.draw(planeIndexBuffer, 0, PLANE_NUM_TRIANGLES);
        solidProgram.setVertexBuffer('aPos', null, 0, 3);
        solidProgram.setVertexBuffer('aColor', null, 3, 3);
        
        solidProgram.setMatrix4('uBodyMat', null);
        solidProgram.setMatrix4('uCameraMat', null);
        solidProgram.setMatrix4('uPerspectiveMat', null);

        // billboards
        
        billboardProgram.use();
        billboardProgram.setBlendFactors(BlendFactor.ONE, BlendFactor.ONE);
        billboardProgram.setDepthTest(false);
        billboardProgram.setFaceCulling(null);

        billboardProgram.setMatrix4('uCameraMat', cameraTransform);
        billboardProgram.setMatrix4('uPerspectiveMat', perspectiveTransform);

        fullTransform.identity();
        fullTransform.append(cubeTilt);
        fullTransform.append(cubeTransform);
        fullTransform.append(sceneTransform);
        billboardProgram.setMatrix4('uBodyMat', fullTransform);

        // The particles should not be affected by the camera rotating and translating
        // The particles should be affected by the camera scaling
        // The particles should not be affected by the fullTransform rotating and translating
        // The particles should be affected by the fullTransform scaling

        var dammit = 1;
        billboardProgram.setFloat('uBodyScreenScale', dammit);

        billboardProgram.setVertexBuffer('aPos',     billboardVertexBuffer, 0, 3);
        billboardProgram.setVertexBuffer('aCorner',  billboardVertexBuffer, 3, 2);
        billboardProgram.setVertexBuffer('aScale',   billboardVertexBuffer, 5, 1);
        billboardProgram.draw(billboardIndexBuffer, 0, BILLBOARD_NUM_TRIANGLES_PER_BILLBOARD * NUM_BILLBOARDS);
        billboardProgram.setVertexBuffer('aPos',     null, 0, 3);
        billboardProgram.setVertexBuffer('aCorner',  null, 3, 2);
        billboardProgram.setVertexBuffer('aScale',   null, 5, 1);
        
        billboardProgram.setMatrix4('uBodyMat', null);
        billboardProgram.setMatrix4('uCameraMat', null);
        billboardProgram.setMatrix4('uPerspectiveMat', null);
    }
}
