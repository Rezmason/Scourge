package net.rezmason.scourge.lab;

import lime.math.Matrix4;
import lime.math.Vector4;
import lime.utils.Float32Array;
import net.rezmason.gl.*;
import net.rezmason.math.Vec4;

class CubeLab extends Lab {

    inline static var FpV:Int = 3 + 3; // floats per vertex
    inline static var NUM_VERTICES = 8;
    inline static var NUM_TRIANGLES = 12;
    
    var program:Program;
    var vertexBuffer:VertexBuffer;
    var indexBuffer:IndexBuffer;

    var bodyTransform:Matrix4;
    var sceneTransform:Matrix4;
    var fullTransform:Matrix4;
    var cameraTransform:Matrix4;
    
    override function init() {

        bodyTransform = new Matrix4();
        bodyTransform.appendScale(0.5, 0.5, 0.5);

        sceneTransform = new Matrix4();
        sceneTransform.appendTranslation(0, 0, -0.5);

        fullTransform = new Matrix4();

        cameraTransform = new Matrix4();
        var values = [2, 0, 0, 0, 0, -3, 0, 0, 0, 0.5, 2, 1, 0, 0.5, 0, 1];
        for (ike in 0...values.length) cameraTransform.set(ike, values[ike]);

        var vertShader = '
            attribute vec3 aPos;
            attribute vec3 aColor;
            uniform mat4 uBodyMat;
            uniform mat4 uCameraMat;
            varying vec4 vColor;
            void main(void) {
                vColor = vec4(aColor, 1.0);
                gl_Position = uCameraMat * uBodyMat * vec4(aPos, 1.0);
            }
        ';
        var fragShader = '
            varying vec4 vColor;

            void main(void) {
                gl_FragColor = vColor;
            }
        ';

        vertexBuffer = new VertexBuffer(NUM_VERTICES, FpV);
        var vert = [
        //   X   Y   Z  
            -1, -1, -1,  0, 0, 0,
            -1, -1,  1,  0, 0, 1,
            -1,  1, -1,  0, 1, 0,
            -1,  1,  1,  0, 1, 1,
             1, -1, -1,  1, 0, 0,
             1, -1,  1,  1, 0, 1,
             1,  1, -1,  1, 1, 0,
             1,  1,  1,  1, 1, 1,
        ];

        /*

           Y

           2---------6
          /|        /|
         / |       / |
        3---------7  |
        |  |      |  |
        |  |      |  |
        |  |      |  |
        |  0------|--4   X
        | /       | /
        |/        |/
        1---------5

      Z

        */

        for (ike in 0...vertexBuffer.numVertices * FpV) vertexBuffer.mod(ike, vert[ike]);
        vertexBuffer.upload();

        indexBuffer = new IndexBuffer(NUM_TRIANGLES * 3);
        var ind = [
            0, 2, 3,   3, 1, 0,
            0, 4, 6,   6, 2, 0,
            0, 1, 5,   5, 4, 0,
            7, 6, 4,   4, 5, 7,
            7, 5, 1,   1, 3, 7,
            7, 3, 2,   2, 6, 7,
        ];
        for (ike in 0...indexBuffer.numIndices) indexBuffer.mod(ike, ind[ike]);
        indexBuffer.upload();

        program = new Program(vertShader, fragShader, []);
    }

    override function update():Void {
        bodyTransform.appendRotation(2, Vector4.Y_AXIS);
        fullTransform.identity();
        fullTransform.append(bodyTransform);
        fullTransform.append(sceneTransform);
    }

    override function draw():Void {
        program.use();
        program.setDepthTest(true);
        program.setVertexBuffer('aPos',     vertexBuffer, 0, 3);
        program.setVertexBuffer('aColor',   vertexBuffer, 3, 3);
        program.setMatrix4('uBodyMat', fullTransform);
        program.setMatrix4('uCameraMat', cameraTransform);
        program.setRenderTarget(renderTarget);
        program.clear(new Vec4(0, 0, 0, 1));
        program.draw(indexBuffer, 0, NUM_TRIANGLES);
    }
}
