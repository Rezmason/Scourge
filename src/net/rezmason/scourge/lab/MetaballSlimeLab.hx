package net.rezmason.scourge.lab;

import lime.Assets.*;
import lime.math.Matrix4;
import lime.math.Vector4;
import net.rezmason.gl.*;
import net.rezmason.math.Vec4;

class MetaballSlimeLab extends Lab {

    inline static var FpV:Int = 3 + 2; // floats per vertex
    inline static var VpB:Int = 4; // vertices per billboard
    
    var metaballLab:MetaballLab;

    var metaballTexture:Texture;
    var globTexture:Texture;
    var program:Program;

    var renderTarget:RenderTarget;

    var vertexBuffer:VertexBuffer;
    var indexBuffer:IndexBuffer;

    var color:Vector4;
    var light:Vector4;
    var params:Vector4;
    var params2:Vector4;

    var lightVector:Vector4;
    var globMat:Matrix4;
    var time:Float;

    public function new(width:Int, height:Int):Void {
        super(width, height);

        metaballLab = new MetaballLab(width, height);

        time = 0;
        var heightThreshold:Float = 0.7;
        var heightEnvelope:Float = 0.02;

        var lower:Float = heightThreshold - heightEnvelope;
        var upper:Float = heightThreshold + heightEnvelope;

        var innerGlow:Float = 0.8;
        var outerGlow:Float = 0.2;
        var shine:Float = 0.3;

        var nudge:Float = 0.005;

        params = new Vector4(lower, upper, innerGlow, shine);
        params2 = new Vector4(nudge, outerGlow, 0, 0);
        color = new Vector4(0.4, 0.9, 0.1, 1.0);

        light = new Vector4(1, 1, 1, 1);
        light.normalize();

        globMat = new Matrix4();
        
        metaballTexture = metaballLab.rtt;
        globTexture = new ImageTexture(getImage('metaballs/glob.png'));

        renderTarget = new ViewportRenderTarget();
        cast(renderTarget, ViewportRenderTarget).resize(width, height);

        var vertShader = '
            attribute vec3 aPos;
            attribute vec2 aUV;

            varying vec2 vUV;

            void main(void) {
                vUV = aUV;
                vec4 pos = vec4(aPos, 1.0);
                pos.z = clamp(pos.z, 0.0, 1.0);
                gl_Position = pos;
            }
        ';
        var fragShader = '
            varying vec2 vUV;

            uniform sampler2D uMetaballSampler;
            uniform sampler2D uGlobSampler;
            uniform vec4 uParams;
            uniform vec4 uParams2;
            uniform vec4 uColor;
            uniform vec4 uLight;
            uniform mat4 uGlobMat;
            
            void main(void) {
                
                float lower = uParams.x;
                float upper = uParams.y;
                float innerGlow = uParams.z;
                float outerGlow = uParams2.y;
                float nudge = uParams2.x;
                float shine = uParams.w;

                vec4 mbData = texture2D(uMetaballSampler, vUV);
                float height = mbData.b + mbData.r * 0.5;

                float brightness1 = outerGlow * (height / lower);
                float brightness2 = 0.9 + 0.1 * height * (innerGlow - height);
                brightness2 = brightness2 * min(1.0, (height - lower) / (upper - lower)) + outerGlow;
                
                float isInside = (height < lower) ? 0.0 : 1.0; // Using conditions to create multipliers makes AGAL happier
                float brightness = brightness1 * (1.0 - isInside) + brightness2 * isInside;
                
                float x1 = texture2D(uMetaballSampler, vUV - vec2(nudge, 0.)).b;
                float y1 = texture2D(uMetaballSampler, vUV - vec2(0., nudge)).b;
                
                float x2 = texture2D(uMetaballSampler, vUV + vec2(nudge, 0.)).b;
                float y2 = texture2D(uMetaballSampler, vUV + vec2(0., nudge)).b;
                
                vec3 surfaceNormal = vec3(x2 - x1 + 0.5, y2 - y1 + 0.5, 0.5);
                float lighting = dot(surfaceNormal, uLight.xyz) * isInside + (1.0 - isInside);

                vec2 textureNormal = (uGlobMat * vec4(surfaceNormal, 1.0)).xy;
                float texture = texture2D(uGlobSampler, textureNormal).g * shine * isInside;

                // gl_FragColor = vec4(0., 0., height, 1.0);
                // gl_FragColor = vec4(vec3(brightness), 1.0);
                // gl_FragColor = vec4(surfaceNormal, 1.0);
                // gl_FragColor = vec4(brightness * vec3(lighting), 1.0);
                // gl_FragColor = vec4(brightness * vec3(texture), 1.0);
                
                gl_FragColor = vec4(brightness * (uColor.rgb * lighting + texture), 1.0);
            }
        ';

        vertexBuffer = new VertexBuffer(VpB, FpV);
        var vert = [
            -1, -1, 0, 0, 1,
            -1,  1, 0, 0, 0,
             1,  1, 0, 1, 0,
             1, -1, 0, 1, 1,
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
    }

    override public function render() {
        metaballLab.render();
        super.render();
    }

    override function update():Void {
        time += 0.025;

        globMat.identity();
        globMat.appendTranslation(-0.5, -0.5, -0.0);
        globMat.appendRotation(time, Vector4.Z_AXIS);
        globMat.appendTranslation(0.5, 0.5, 0.0);

        //params[2] = Math.cos(time) + 0.8;
        //params[3] = Math.cos(time * 3 / 2) + 1;
    }

    override function draw():Void {
        program.use();
        program.setBlendFactors(BlendFactor.ONE, BlendFactor.ONE);
        program.setDepthTest(false);

        program.setTexture('uMetaballSampler', metaballTexture); // uMetaballSampler contains our metaballTexture
        program.setTexture('uGlobSampler', globTexture, 1); // uGlobSampler contains our glob texture
        program.setVector4('uParams', params);
        program.setVector4('uParams2', params2);
        program.setVector4('uColor', color);
        program.setVector4('uLight', light);
        program.setMatrix4('uGlobMat', globMat);
        
        program.setVertexBuffer('aPos',     vertexBuffer, 0, 3); // aPos contains x,y,z
        program.setVertexBuffer('aUV',      vertexBuffer, 3, 2); // aUV contains u,v

        program.setRenderTarget(renderTarget);
        program.clear(new Vec4(0, 0, 0, 1));
        program.draw(indexBuffer, 0, 2);

        program.setVertexBuffer('aPos',     null, 0, 3);
        program.setVertexBuffer('aUV',      null, 3, 2);

        program.setTexture('uMetaballSampler', null);
        program.setTexture('uGlobSampler', null, 1);
    }
}
