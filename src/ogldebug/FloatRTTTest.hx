package ogldebug;

import haxe.io.BytesOutput;
import lime.graphics.opengl.GL;
import lime.graphics.opengl.GLBuffer;
import lime.graphics.opengl.GLFramebuffer;
import lime.graphics.opengl.GLProgram;
import lime.graphics.opengl.GLTexture;
import lime.graphics.opengl.GLUniformLocation;
import lime.utils.ArrayBufferView;
import lime.utils.Float32Array;
import lime.utils.GLUtils;
import lime.utils.Int16Array;
import lime.utils.UInt16Array;
import net.rezmason.math.FelzenszwalbSDF;
import net.rezmason.utils.HalfFloatUtil;

using StringTools;

class FloatRTTTest {

    inline static var RED        = 0x1903;
    inline static var HALF_FLOAT = #if desktop 0x140B #else 0x8D61 #end;

    inline static var RGBA32F    = 0x8814;
    inline static var R32F       = 0x822E;

    inline static var RGBA16F    = 0x881A;
    inline static var R16F       = 0x822D;


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

    var halfFloatTexture:GLTexture;

    public function new(width:UInt, height:UInt):Void {
        this.width = width;
        this.height = height;

        var extensions = [
            'OES_texture_float', 
            'OES_texture_float_linear', 
            'OES_texture_half_float',
            'OES_texture_half_float_linear',
            // 'WEBGL_color_buffer_float', 'EXT_color_buffer_half_float', // WebGL 1 
            // 'EXT_color_buffer_float', // WebGL 2 
        ];

        for (extension in extensions) GL.getExtension(extension);

        rttTexture = GL.createTexture();
        rttFrameBuffer = GL.createFramebuffer();
        GL.bindFramebuffer(GL.FRAMEBUFFER, rttFrameBuffer);
        GL.bindTexture(GL.TEXTURE_2D, rttTexture);
        GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.LINEAR);
        GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.LINEAR);
        GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_S, GL.CLAMP_TO_EDGE);
        GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_T, GL.CLAMP_TO_EDGE);
        GL.texImage2D(GL.TEXTURE_2D, 0, #if desktop RGBA32F #else GL.RGBA #end, width, height, 0, GL.RGBA, GL.FLOAT, null);
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
        GL.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, indexBuffer);
        GL.bufferData(GL.ELEMENT_ARRAY_BUFFER, indexData, GL.STATIC_DRAW);

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

        rttProgram = makeProgram(rttVertShader, rttFragShader, extensions);

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
                
                //*
                gl_FragColor = vec4(vec3(texture2D(uSampler, vPos).r), 1.0);
                /**/

                /*
                float nudge = 0.01;
                float x1 = texture2D(uSampler, vPos - vec2(nudge, 0.)).r;
                float y1 = texture2D(uSampler, vPos - vec2(0., nudge)).r;
                float x2 = texture2D(uSampler, vPos + vec2(nudge, 0.)).r;
                float y2 = texture2D(uSampler, vPos + vec2(0., nudge)).r;
                vec3 surfaceNormal = vec3(x2 - x1 + 0.5, y2 - y1 + 0.5, 0.5);
                gl_FragColor = vec4(surfaceNormal, 1.0);
                /**/

                /*
                float value = texture2D(uSampler, vPos).r;
                if (value > 0.5) gl_FragColor = vec4(1.0, 1.0, 1.0, 1.0);
                else if (value > 0.0) gl_FragColor = vec4(1.0, 0.0, 0.0, 1.0);
                else if (value > -0.5) gl_FragColor = vec4(1.0, 1.0, 0.0, 1.0);
                else gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
                /**/
            }
        ';

        halfFloatTexture = generateHalfFloatLuminanceTexture(true, false);

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
        
        // return;

        GL.useProgram(postProgram);
        GL.vertexAttribPointer(postPosLocation, 2, GL.FLOAT, false, 4 * 2, 0);
        GL.enableVertexAttribArray(postPosLocation);
        GL.activeTexture(GL.TEXTURE0);
        
        GL.bindTexture(GL.TEXTURE_2D, halfFloatTexture); // rttTexture | halfFloatTexture


        GL.uniform1i(postSamplerLocation, 0);
        GL.bindFramebuffer(GL.FRAMEBUFFER, null);
        GL.viewport(0, 0, width, height);
        GL.clearColor(0, 0, 0, 1);
        GL.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT);
        GL.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, indexBuffer);
        GL.drawElements(GL.TRIANGLES, 2 * 3, GL.UNSIGNED_SHORT, 0);
        GL.disableVertexAttribArray(postPosLocation);
        GL.activeTexture(GL.TEXTURE0);
        GL.bindTexture(GL.TEXTURE_2D, null);
        GL.uniform1i(postSamplerLocation, 0);
    }

    function generateHalfFloatLuminanceTexture(halfFloat, singleChannel) {
        //*
        function traceData(data:Array<Float>, width, height) {
            var max = 1.;
            for (float in data) {
                // if (float == Math.POSITIVE_INFINITY || float == Math.NEGATIVE_INFINITY) continue;
                if (max < float) max = float;
            }
            var str = '\n';
            for (ike in 0...height) {
                for (jen in 0...width) {
                    var float = data[width * ike + jen];
                    str += String.fromCharCode(97 + Std.int(float * 25 / max));
                    // str += float == 0 ? ' ' : '•';
                }
                str += '\n';
            }
            trace(str);
        }
        /**/

        var data:Array<Float> = [for (ike in 0...width * height) 0];
        //*
        for (ike in 0...height) {
            for (jen in 0...width) {
                var x = ike / (height - 1);
                var y = jen / (width - 1);
                var circ1 = Math.sqrt(Math.pow(x - 0.3, 2) + Math.pow(y - 0.3, 2)) < 0.15;
                var circ2 = Math.sqrt(Math.pow(x - 0.7, 2) + Math.pow(y - 0.7, 2)) < 0.15;
                data[ike * width + jen] = circ1 || circ2 ? 1 : 0;
            }
        }
        /**/

        data = FelzenszwalbSDF.computeSignedDistanceField(width, height, data);
        // traceData(data, width, height);

        var output:BytesOutput = new BytesOutput();
        for (ike in 0...width) {
            for (jen in 0...height) {
                var val = data[ike * width + jen] / 500;
                if (halfFloat) {
                    output.writeUInt16(HalfFloatUtil.floatToHalfFloat( val)); // Red
                    if (!singleChannel) {
                        output.writeUInt16(HalfFloatUtil.floatToHalfFloat(-val)); // Green
                        output.writeUInt16(HalfFloatUtil.floatToHalfFloat(-val)); // Blue
                        output.writeUInt16(HalfFloatUtil.floatToHalfFloat(   1)); // Alpha
                    }
                } else {
                    output.writeFloat( val); // Red
                    if (!singleChannel) {
                        output.writeFloat(-val); // Green
                        output.writeFloat(-val); // Blue
                        output.writeFloat(   1); // Alpha
                    }
                }
            }
        }

        var type = halfFloat ? HALF_FLOAT : GL.FLOAT;
        
        var textureData:ArrayBufferView;
        if (halfFloat) textureData = UInt16Array.fromBytes(output.getBytes());
        else textureData = Float32Array.fromBytes(output.getBytes());

        var internalFormat;
        if (halfFloat) {
            if (singleChannel) internalFormat = #if desktop R16F #else GL.LUMINANCE #end ;
            else internalFormat = #if desktop RGBA16F #else GL.RGBA #end;
        } else {
            if (singleChannel) internalFormat = #if desktop R32F #else GL.LUMINANCE #end ;
            else internalFormat = #if desktop RGBA32F #else GL.RGBA #end;
        }

        trace(type.hex(), halfFloat, singleChannel, internalFormat.hex());
        
        var format;
        if (singleChannel) format = #if desktop RED #else GL.LUMINANCE #end ;
        else format = GL.RGBA;

        var nativeTexture = GL.createTexture();
        GL.bindTexture(GL.TEXTURE_2D, nativeTexture);
        GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_S, GL.CLAMP_TO_EDGE);
        GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_T, GL.CLAMP_TO_EDGE);
        GL.texImage2D(GL.TEXTURE_2D, 0, internalFormat, width, height, 0, format, type, textureData);
        GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.LINEAR);
        GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.LINEAR);
        GL.bindTexture(GL.TEXTURE_2D, null);

        return nativeTexture;
    }
}
