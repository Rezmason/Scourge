package ogldebug;

import lime.graphics.opengl.GL;
import lime.graphics.opengl.GLBuffer;
import lime.graphics.opengl.GLFramebuffer;
import lime.graphics.opengl.GLProgram;
import lime.graphics.opengl.GLTexture;
import lime.graphics.opengl.GLUniformLocation;
import lime.utils.Float32Array;
import lime.utils.GLUtils;
import lime.utils.Int16Array;

class FloatRTTTest {
    var width:UInt;
    var height:UInt;
    var time:Float = 0;
    
    var vertexBuffer:GLBuffer;
    var indexBuffer:GLBuffer;
    
    var postPosLocation:Int;
    var postProgram:GLProgram;
    var postSamplerLocation:GLUniformLocation;

    var rttFrameBuffer:GLFramebuffer;
    var rttPhaseLocation:GLUniformLocation;
    var rttPosLocation:Int;
    var rttProgram:GLProgram;
    var rttTexture:GLTexture;

    public function new(width:UInt, height:UInt):Void {
        this.width = width;
        this.height = height;

        for (extension in ['OES_texture_float', 'OES_texture_float_linear']) GL.getExtension(extension);

        rttTexture = GL.createTexture();
        rttFrameBuffer = GL.createFramebuffer();
        GL.bindFramebuffer(GL.FRAMEBUFFER, rttFrameBuffer);
        GL.bindTexture(GL.TEXTURE_2D, rttTexture);
        GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.LINEAR);
        GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.LINEAR);
        GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_S, GL.CLAMP_TO_EDGE);
        GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_T, GL.CLAMP_TO_EDGE);
        GL.texImage2D(GL.TEXTURE_2D, 0, GL.RGBA, width, height, 0, GL.RGBA, GL.FLOAT, null);
        GL.framebufferTexture2D(GL.FRAMEBUFFER, GL.COLOR_ATTACHMENT0, GL.TEXTURE_2D, rttTexture, 0);
        GL.bindTexture(GL.TEXTURE_2D, null);
        GL.bindRenderbuffer(GL.RENDERBUFFER, null);
        GL.bindFramebuffer(GL.FRAMEBUFFER, null);

        vertexBuffer = GL.createBuffer();
        var vertexData = new Float32Array(4 * 2);
        var vert = [
            -1, -1,
            -1,  1,
             1,  1,
             1, -1,
        ];
        for (ike in 0...4 * 2) vertexData[ike] = vert[ike];
        GL.bindBuffer(GL.ARRAY_BUFFER, vertexBuffer);
        GL.bufferData(GL.ARRAY_BUFFER, vertexData, GL.STATIC_DRAW);

        indexBuffer = GL.createBuffer();
        var indexData = new Int16Array(6);
        var ind = [
            0, 1, 2,
            0, 2, 3,
        ];
        for (ike in 0...6) indexData[ike] = ind[ike];
        GL.bindBuffer(GL.ARRAY_BUFFER, indexBuffer);
        GL.bufferData(GL.ARRAY_BUFFER, indexData, GL.STATIC_DRAW);

        var rttVertShader = '
            attribute vec2 aPos;
            varying vec2 vPos;
            void main(void) {
                vPos = aPos * 0.5;
                gl_Position = vec4(aPos, 0.0, 1.0);
            }
        ';
        var rttFragShader = '
            varying vec2 vPos;
            uniform float uPhase;
            void main(void) {
                float value = cos((length(vPos) + uPhase * -0.1) * 2.0 * 3.14 * 4.0);
                gl_FragColor = vec4(vec3(value), 1.0);
            }
        ';

        rttProgram = makeProgram(rttVertShader, rttFragShader, ['OES_texture_float', 'OES_texture_float_linear']);

        var postVertShader = '
            attribute vec2 aPos;
            varying vec2 vPos;

            void main(void) {
                vPos = aPos * 0.5 + 0.5;
                vec4 pos = vec4(aPos, 0.0, 1.0);
                pos.z = clamp(pos.z, 0.0, 1.0);
                gl_Position = pos;
            }
        ';
        var postFragShader = '
            varying vec2 vPos;
            uniform sampler2D uSampler;

            void main(void) {
                
                /*
                gl_FragColor = texture2D(uSampler, vPos);
                /**/

                //*
                float nudge = 0.01;
                float x1 = texture2D(uSampler, vPos - vec2(nudge, 0.)).b;
                float y1 = texture2D(uSampler, vPos - vec2(0., nudge)).b;
                float x2 = texture2D(uSampler, vPos + vec2(nudge, 0.)).b;
                float y2 = texture2D(uSampler, vPos + vec2(0., nudge)).b;
                vec3 surfaceNormal = vec3(x2 - x1 + 0.5, y2 - y1 + 0.5, 0.5);
                gl_FragColor = vec4(surfaceNormal, 1.0);
                /**/

                /*
                float value = texture2D(uSampler, vPos).b;
                if (value > 0.5) gl_FragColor = vec4(1.0, 1.0, 1.0, 1.0);
                else if (value > 0.0) gl_FragColor = vec4(1.0, 0.0, 0.0, 1.0);
                else if (value > -0.5) gl_FragColor = vec4(1.0, 1.0, 0.0, 1.0);
                else gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
                /**/
            }
        ';

        postProgram = makeProgram(postVertShader, postFragShader, ['OES_texture_float', 'OES_texture_float_linear']);

        rttPosLocation = GL.getAttribLocation(rttProgram, 'aPos');
        rttPhaseLocation = GL.getUniformLocation(rttProgram, 'uPhase');
        postPosLocation = GL.getAttribLocation(postProgram, 'aPos');
        postSamplerLocation = GL.getUniformLocation(postProgram, 'uSampler');
    }

    public function makeProgram(vertSource:String, fragSource:String, extensions:Array<String>):GLProgram {
        var extensionPreamble = '\n';
        for (extension in extensions) {
            GL.getExtension(extension);
            extensionPreamble += '#extension GL_$extension : enable\n';
        }
        #if !desktop extensionPreamble += 'precision mediump float;\n'; #end
        vertSource = extensionPreamble + vertSource;
        fragSource = extensionPreamble + fragSource;
        return GLUtils.createProgram(vertSource, fragSource);
    }

    public function render() {

        time += 0.01;

        GL.useProgram(rttProgram);
        GL.bindBuffer(GL.ARRAY_BUFFER, vertexBuffer);
        GL.vertexAttribPointer(rttPosLocation, 2, GL.FLOAT, false, 4 * 2, 0);
        GL.enableVertexAttribArray(rttPosLocation);
        GL.uniform1f(rttPhaseLocation, time);
        GL.bindFramebuffer(GL.FRAMEBUFFER, rttFrameBuffer);
        GL.viewport(0, 0, width, height);
        GL.clearColor(0, 0, 0, 1);
        GL.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT);
        GL.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, indexBuffer);
        GL.drawElements(GL.TRIANGLES, 2 * 3, GL.UNSIGNED_SHORT, 0);
        GL.disableVertexAttribArray(rttPosLocation);
        GL.useProgram(postProgram);
        GL.vertexAttribPointer(postPosLocation, 2, GL.FLOAT, false, 4 * 2, 0);
        GL.enableVertexAttribArray(postPosLocation);
        GL.activeTexture(GL.TEXTURE0);
        GL.bindTexture (GL.TEXTURE_2D, rttTexture);
        GL.uniform1i(postSamplerLocation, 0);
        GL.bindFramebuffer(GL.FRAMEBUFFER, null);
        GL.viewport(0, 0, width, height);
        GL.clearColor(0, 0, 0, 1);
        GL.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT);
        GL.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, indexBuffer);
        GL.drawElements(GL.TRIANGLES, 2 * 3, GL.UNSIGNED_SHORT, 0);
        GL.disableVertexAttribArray(postPosLocation);
        GL.activeTexture(GL.TEXTURE0);
        GL.bindTexture (GL.TEXTURE_2D, null);
        GL.uniform1i(postSamplerLocation, 0);
    }
}
