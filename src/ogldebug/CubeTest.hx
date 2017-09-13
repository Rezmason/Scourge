package ogldebug;

import lime.graphics.opengl.GL;
import lime.graphics.opengl.GLBuffer;
import lime.graphics.opengl.GLProgram;
import lime.graphics.opengl.GLUniformLocation;
import lime.graphics.opengl.WebGLContext;
import lime.math.Matrix4;
import lime.math.Vector4;
import lime.utils.Float32Array;
import lime.utils.GLUtils;
import lime.utils.Int16Array;

class CubeTest {

    inline static var FpV:Int = 3 + 3; // floats per vertex
    inline static var NUM_VERTICES = 8;
    inline static var NUM_TRIANGLES = 12;
    
    var context:WebGLContext;

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

        context = GL.context;

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

        vertexBuffer = context.createBuffer();
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
        context.bindBuffer(context.ARRAY_BUFFER, vertexBuffer);
        context.bufferData(context.ARRAY_BUFFER, vertexData, context.STATIC_DRAW);

        indexBuffer = context.createBuffer();
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
        context.bindBuffer(context.ELEMENT_ARRAY_BUFFER, indexBuffer);
        context.bufferData(context.ELEMENT_ARRAY_BUFFER, indexData, context.STATIC_DRAW);

        #if !desktop
            vertShader = 'precision mediump float;\n' + vertShader;
            fragShader = 'precision mediump float;\n' + fragShader;
        #end

        program = GLUtils.createProgram(vertShader, fragShader);
        posLocation = context.getAttribLocation(program, 'aPos');
        colorLocation = context.getAttribLocation(program, 'aColor');
        bodyMatLocation = context.getUniformLocation(program, 'uBodyMat');
        cameraMatLocation = context.getUniformLocation(program, 'uCameraMat');
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

        context.useProgram(program);
        context.enable(context.DEPTH_TEST);

        context.enable(context.CULL_FACE);
        context.cullFace(context.BACK);
        
        context.bindBuffer(context.ARRAY_BUFFER, vertexBuffer);
        
        context.vertexAttribPointer(posLocation, 3, context.FLOAT, false, 4 * FpV, 4 * 0);
        context.enableVertexAttribArray(posLocation);

        context.vertexAttribPointer(colorLocation, 3, context.FLOAT, false, 4 * FpV, 4 * 3);
        context.enableVertexAttribArray(colorLocation);

        context.uniformMatrix4fv(bodyMatLocation, false, fullTransform);
        context.uniformMatrix4fv(cameraMatLocation, false, cameraTransform);

        context.viewport(0, 0, width, height);
        context.clearColor(0, 0, 0, 1);
        context.clear(context.COLOR_BUFFER_BIT | context.DEPTH_BUFFER_BIT);
        context.bindBuffer(context.ELEMENT_ARRAY_BUFFER, indexBuffer);
        context.drawElements(context.TRIANGLES, NUM_TRIANGLES * 3, context.UNSIGNED_SHORT, 0);
    }
}
