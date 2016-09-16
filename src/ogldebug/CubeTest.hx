package ogldebug;

import lime.graphics.opengl.GL;
import lime.graphics.opengl.GLBuffer;
import lime.graphics.opengl.GLProgram;
import lime.graphics.opengl.GLUniformLocation;
import lime.math.Matrix4;
import lime.math.Vector4;
import lime.utils.Float32Array;
import lime.utils.GLUtils;
import lime.utils.Int16Array;

class CubeTest {

    inline static var FpV:Int = 3 + 3; // floats per vertex
    inline static var NUM_VERTICES = 8;
    inline static var NUM_TRIANGLES = 12;
    
    var width:UInt;
    var height:UInt;
    
    var program:GLProgram;
    var vertexBuffer:GLBuffer;
    var indexBuffer:GLBuffer;

    var bodyTransform:Matrix4;
    var sceneTransform:Matrix4;
    var fullTransform:Matrix4;
    var cameraTransform:Matrix4;

    var time:Float = 0;

    var posLocation:Int;
    var colorLocation:Int;
    var bodyMatLocation:GLUniformLocation;
    var cameraMatLocation:GLUniformLocation;
    
    public function new(width, height) {
        this.width = width;
        this.height = height;
        
        bodyTransform = new Matrix4();
        bodyTransform.appendRotation(135, Vector4.Y_AXIS);
        bodyTransform.appendRotation(Math.acos(1 / Math.sqrt(3)) * 180 / Math.PI, Vector4.X_AXIS);

        sceneTransform = new Matrix4();
        sceneTransform.appendTranslation(0, 0, -3);

        fullTransform = new Matrix4();

        cameraTransform = perspectiveRH(1, 1, 1, 10);

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

        vertexBuffer = GL.createBuffer();
        var vertexData = new Float32Array(NUM_VERTICES * FpV);
        var vert = [
             1, -1, -1,  1, 0, 0,
             1, -1,  1,  1, 0, 1,
             1,  1, -1,  1, 1, 0,
             1,  1,  1,  1, 1, 1,
            -1, -1, -1,  0, 0, 0,
            -1, -1,  1,  0, 0, 1,
            -1,  1, -1,  0, 1, 0,
            -1,  1,  1,  0, 1, 1,
        ];

        for (ike in 0...NUM_VERTICES * FpV) vertexData[ike] = vert[ike];
        GL.bindBuffer(GL.ARRAY_BUFFER, vertexBuffer);
        GL.bufferData(GL.ARRAY_BUFFER, vertexData, GL.STATIC_DRAW);

        indexBuffer = GL.createBuffer();
        var numIndices = NUM_TRIANGLES * 3;
        var indexData = new Int16Array(numIndices);
        var ind = [
            0, 2, 3,   3, 1, 0,
            0, 4, 6,   6, 2, 0,
            0, 1, 5,   5, 4, 0,
            7, 6, 4,   4, 5, 7,
            7, 5, 1,   1, 3, 7,
            7, 3, 2,   2, 6, 7,
        ];
        for (ike in 0...numIndices) indexData[ike] = ind[ike];
        GL.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, indexBuffer);
        GL.bufferData(GL.ELEMENT_ARRAY_BUFFER, indexData, GL.STATIC_DRAW);

        #if !desktop
            vertShader = 'precision mediump float;\n' + vertShader;
            fragShader = 'precision mediump float;\n' + fragShader;
        #end

        program = GLUtils.createProgram(vertShader, fragShader);
        posLocation = GL.getAttribLocation(program, 'aPos');
        colorLocation = GL.getAttribLocation(program, 'aColor');
        bodyMatLocation = GL.getUniformLocation(program, 'uBodyMat');
        cameraMatLocation = GL.getUniformLocation(program, 'uCameraMat');
    }

    function perspectiveRH(width, height, zNear, zFar) {
        var mat = new Matrix4();

        mat.set(0, 2 * zNear / width);
        mat.set(5, 2 * zNear / height);
        mat.set(10, zFar / (zNear - zFar));
        mat.set(11, -1);
        mat.set(14, zNear * zFar / (zNear - zFar));

        return mat;
    }

    public function render() {
        time += 0.01;
        bodyTransform.appendRotation(2, Vector4.Y_AXIS);
        sceneTransform.identity();
        sceneTransform.appendTranslation(0, Math.sin(time * 7) * 0.1, -3);
        fullTransform.identity();
        fullTransform.append(bodyTransform);
        fullTransform.append(sceneTransform);

        GL.useProgram(program);
        GL.enable(GL.DEPTH_TEST);

        GL.enable(GL.CULL_FACE);
        GL.cullFace(GL.BACK);
        
        GL.bindBuffer(GL.ARRAY_BUFFER, vertexBuffer);
        
        GL.vertexAttribPointer(posLocation, 3, GL.FLOAT, false, 4 * FpV, 4 * 0);
        GL.enableVertexAttribArray(posLocation);

        GL.vertexAttribPointer(colorLocation, 3, GL.FLOAT, false, 4 * FpV, 4 * 3);
        GL.enableVertexAttribArray(colorLocation);

        GL.uniformMatrix4fv(bodyMatLocation, false, fullTransform);
        GL.uniformMatrix4fv(cameraMatLocation, false, cameraTransform);

        GL.viewport(0, 0, width, height);
        GL.clearColor(0, 0, 0, 1);
        GL.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT);
        GL.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, indexBuffer);
        GL.drawElements(GL.TRIANGLES, NUM_TRIANGLES * 3, GL.UNSIGNED_SHORT, 0);
    }
}
