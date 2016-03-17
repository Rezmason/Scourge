package net.rezmason.scourge.lab;

import lime.math.Matrix4;
import lime.math.Vector4;
import net.rezmason.gl.*;
import net.rezmason.math.Vec4;

class RTTLab extends Lab {

    inline static var FpV:Int = 2; // floats per vertex
    inline static var VpB:Int = 4; // vertices per billboard
    
    var program:Program;
    var vertexBuffer:VertexBuffer;
    var indexBuffer:IndexBuffer;
    var viewportRT:ViewportRenderTarget;
    var rtt:RenderTargetTexture;

    var color:Vector4;

    public function new(width:Int, height:Int):Void {

        super(width, height);

        rtt = new RenderTargetTexture(UNSIGNED_BYTE);
        rtt.resize(Std.int(width / 16), Std.int(height / 16));

        viewportRT = new ViewportRenderTarget();
        viewportRT.resize(width, height);

        var vertShader = '
            attribute vec2 aPos;
            varying vec2 vUV;

            void main(void) {
                vUV = aPos * 0.5 + 0.5;
                gl_Position = vec4(aPos, 1.0, 1.0);
            }
        ';
        var fragShader = '
            uniform vec4 uColor;
            varying vec2 vUV;
            uniform sampler2D uRTT;
            void main(void) {
                gl_FragColor = uColor + texture2D(uRTT, vUV);
            }
        ';

        vertexBuffer = new VertexBuffer(VpB, FpV);
        var vert = [
            -1,  0,
             0, -1,
             1,  0,
             0,  1,
        ];
        for (ike in 0...VpB * FpV) vertexBuffer.mod(ike, vert[ike]);
        vertexBuffer.upload();

        indexBuffer = new IndexBuffer(6);
        var ind = [
            0, 1, 2,
            0, 2, 3,
        ];
        for (ike in 0...6) indexBuffer.mod(ike, ind[ike]);
        indexBuffer.upload();

        var extensions = ['OES_texture_float', 'OES_standard_derivatives', 'OES_texture_float_linear'];
        program = new Program(vertShader, fragShader, extensions);

        color = new Vector4(0, 0, 0, 1);
    }

    override function update():Void {
        
    }

    override function draw():Void {
        program.use();
        program.setVertexBuffer('aPos',     vertexBuffer, 0, 2);
        
        program.setRenderTarget(rtt.renderTarget);
        program.clear(new Vec4(0, 0, 0, 1));
        color.x = 1;
        program.setVector4('uColor', color);
        program.draw(indexBuffer, 0, 2);
        color.x = 0;

        program.setRenderTarget(viewportRT);
        program.clear(new Vec4(0, 0, 0, 1));
        program.setTexture('uRTT', rtt);
        color.y = 1;
        program.setVector4('uColor', color);
        program.draw(indexBuffer, 0, 2);
        program.setTexture('uRTT', null);
        color.y = 0;
    }
}
