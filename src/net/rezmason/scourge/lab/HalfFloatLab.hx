package net.rezmason.scourge.lab;

import haxe.io.BytesOutput;
import net.rezmason.gl.*;
import net.rezmason.math.FelzenszwalbSDF;
import net.rezmason.utils.HalfFloatUtil;
import net.rezmason.math.Vec4;

class HalfFloatLab extends Lab {

    inline static var FLOATS_PER_VERTEX:Int = 2 + 2;
    inline static var TOTAL_VERTICES:Int = 4;
    inline static var TOTAL_TRIANGLES:Int = 2;
    inline static var TOTAL_INDICES:Int = TOTAL_TRIANGLES * 3;
    
    var dataTexture:Texture;
    var program:Program;

    var vertexBuffer:VertexBuffer;
    var indexBuffer:IndexBuffer;

    override function init() {

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
                output.writeUInt16(HalfFloatUtil.floatToHalfFloat( val)); // Red
                output.writeUInt16(HalfFloatUtil.floatToHalfFloat(-val)); // Green
                output.writeUInt16(HalfFloatUtil.floatToHalfFloat(-val)); // Blue
                output.writeUInt16(HalfFloatUtil.floatToHalfFloat(   1)); // Alpha
            }
        }

        dataTexture = new HalfFloatTexture(width, height, output.getBytes());

        vertexBuffer = new VertexBuffer(TOTAL_VERTICES, FLOATS_PER_VERTEX);
        var vertices = [
            -1, -1,  0,  0, 
            -1,  1,  0,  1, 
             1, -1,  1,  0, 
             1,  1,  1,  1, 
        ];
        for (ike in 0...vertices.length) vertexBuffer.mod(ike, vertices[ike]);
        vertexBuffer.upload();

        indexBuffer = new IndexBuffer(TOTAL_INDICES);
        var ind = [0, 1, 2, 1, 2, 3,];
        for (ike in 0...TOTAL_INDICES) indexBuffer.mod(ike, ind[ike]);
        indexBuffer.upload();

        var vertShader = '
            attribute vec2 aPos;
            attribute vec2 aUV;
            varying vec2 vUV;

            void main(void) {
                vUV = aUV;
                gl_Position = vec4(aPos, 0., 1.0);
            }

            '
            ;
        
        var fragShader = '
            varying vec2 vUV;
            uniform sampler2D uDataSampler;

            void main(void) {
                gl_FragColor = texture2D(uDataSampler, vUV);
            }
            ';

        var extensions = ['OES_texture_float', 'OES_standard_derivatives', 'OES_texture_float_linear'];
        program = new Program(vertShader, fragShader, extensions);
    }

    override function update():Void {}

    override function draw():Void {
        program.use();
        program.setBlendFactors(BlendFactor.ONE, BlendFactor.ONE);
        program.setDepthTest(false);
        program.setFaceCulling(null);

        program.setTexture('uDataSampler', dataTexture, 1); // uDataSampler contains our data texture
        program.setVertexBuffer('aPos', vertexBuffer, 0, 2);
        program.setVertexBuffer('aUV',  vertexBuffer, 2, 2);

        program.setRenderTarget(renderTarget);
        program.clear(new Vec4(0, 0, 0, 1));
        program.draw(indexBuffer, 0, TOTAL_TRIANGLES);
        
        program.setTexture('uDataSampler', null, 1);
        program.setVertexBuffer('aPos', null, 0, 2);
        program.setVertexBuffer('aUV',  null, 2, 2);
    }
}
