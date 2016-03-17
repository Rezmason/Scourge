package net.rezmason.scourge.lab;

import lime.Assets.*;
import lime.math.Matrix4;
import lime.math.Vector4;
import lime.utils.Float32Array;
import net.rezmason.gl.*;
import net.rezmason.scourge.waves.Ripple;
import net.rezmason.scourge.waves.WaveFunctions;
import net.rezmason.scourge.waves.WavePool;
import net.rezmason.math.Vec4;

class MetaballLab extends Lab {

    inline static var GRID_WIDTH:Int = 10;
    inline static var NUM_BALLS:Int = GRID_WIDTH * GRID_WIDTH;

    inline static var FpBV:Int = 3 + 2 + 1 + 1; // floats per ball vertex
    inline static var VpB:Int = 4; // vertices per ball
    inline static var IpB:Int = 6; // indices per ball
    inline static var TpB:Int = 2; // triangles per ball

    var metaballTexture:ImageTexture;
    var program:Program;

    var bodyTransform:Matrix4;
    var cameraTransform:Matrix4;

    public var rtt:RenderTargetTexture;

    var phases:Array<Array<Null<Int>>>;
    var cavity:Array<Array<Null<Int>>>;
    var twitches:Array<Array<Null<Float>>>;

    var vertexBuffer:VertexBuffer;
    var indexBuffer:IndexBuffer;

    var time:Float;

    var pool:WavePool;

    public function new(width, height):Void {

        super(width, height);

        pool = new WavePool(1);
        pool.addRipple(new Ripple(WaveFunctions.bolus, 0.5, 5., 1.0, 2, true));

        time = 0;

        metaballTexture = new ImageTexture(getImage('metaballs/metaball.png'));

        bodyTransform = new Matrix4();
        cameraTransform = new Matrix4();
        var rawData:Float32Array = cameraTransform;
        var ike = 0;
        for (val in [2,0,0,0,0,2,0,0,0,-0,2,1,0,0,0,1]) rawData[ike++] = val;
        cameraTransform = rawData;

        rtt = new RenderTargetTexture(FLOAT);
        rtt.resize(width, height);

        var vertShader = '
            attribute vec3 aPos;
            attribute vec2 aCorner;
            attribute float aScale;
            attribute float aCav;

            uniform mat4 uCameraMat;
            uniform mat4 uBodyMat;

            varying vec2 vUV;
            varying float vCav;

            void main(void) {
                vec4 pos = uBodyMat * vec4(aPos, 1.0);
                pos = uCameraMat * pos;
                pos.xy += ((vec4(aCorner.x, aCorner.y, 1.0, 1.0)).xy) * aScale;

                vUV = aCorner * 0.5 + 0.5;
                vCav = aCav;

                pos.z = clamp(pos.z, 0.0, 1.0);
                gl_Position = pos;
            }
        ';
        var fragShader = '
            varying vec2 vUV;
            varying float vCav;

            uniform sampler2D uSampler;
            
            void main(void) {
                float value = texture2D(uSampler, vUV).b;
                gl_FragColor = vec4(value * vCav, 0.0, value * (1.0 - vCav), 1.0);
            }
        ';

        phases = [];
        cavity = [];
        twitches = [];
        for (ike in 0...GRID_WIDTH) {
            cavity.push([]);
            phases.push([]);
            twitches.push([]);
        }
        
        vertexBuffer = new VertexBuffer(NUM_BALLS * VpB, FpBV);
        indexBuffer = new IndexBuffer(NUM_BALLS * IpB);

        var drunkX:Int = Std.int(GRID_WIDTH / 2);
        var drunkY:Int = Std.int(GRID_WIDTH / 2);
        var numPopulated:Int = 1;
        phases[drunkY][drunkX] = 0;
        twitches[drunkY][drunkX] = Math.random();

        while (numPopulated < NUM_BALLS * 0.5) {
            
            if (Std.random(2) == 0) {
                drunkX = Std.int(Math.min(GRID_WIDTH - 1, Math.max(0, drunkX + Std.random(2) * 2 - 1)));
            } else {
                drunkY = Std.int(Math.min(GRID_WIDTH - 1, Math.max(0, drunkY + Std.random(2) * 2 - 1)));
            }

            if (phases[drunkY][drunkX] == null) {
                var neighbors = [];
                if (drunkY > 0) neighbors.push(phases[drunkY - 1][drunkX]);
                if (drunkY < GRID_WIDTH - 1) neighbors.push(phases[drunkY + 1][drunkX]);
                if (drunkX > 0) neighbors.push(phases[drunkY][drunkX - 1]);
                if (drunkX < GRID_WIDTH - 1) neighbors.push(phases[drunkY][drunkX + 1]);

                var val:Int = NUM_BALLS;
                for (neighbor in neighbors) if (val > neighbor) val = neighbor;
                phases[drunkY][drunkX] = val + 1;

                twitches[drunkY][drunkX] = Math.random();

                numPopulated++;
            }
        }

        for (ike in Std.int(GRID_WIDTH * 0.25)...Std.int(GRID_WIDTH * 0.75)) {
            for (jen in Std.int(GRID_WIDTH * 0.25)...Std.int(GRID_WIDTH * 0.75)) {
                cavity[jen][ike] = 1;
            }
        }

        pool.size = Std.int(GRID_WIDTH);

        var center:Float = (GRID_WIDTH - 1) / (2 * GRID_WIDTH);

        var ballVertTemplate:Array<Float> = [
            0, 0, 0, -1, -1, 0, 0, 
            0, 0, 0, -1,  1, 0, 0, 
            0, 0, 0,  1,  1, 0, 0, 
            0, 0, 0,  1, -1, 0, 0, 
        ];

        var ballIndexTemplate:Array<Int> = [
            0, 1, 2, 0, 3, 4,
        ];

        for (ike in 0...NUM_BALLS) {
            var vBall:Int = ike * VpB * FpBV;
            for (jen in 0...FpBV * VpB) {
                vertexBuffer.mod(vBall + jen, ballVertTemplate[jen]);
            }
        }

        for (ike in 0...NUM_BALLS) {

            var vBall:Int = ike * VpB;

            var x:Float = (ike % GRID_WIDTH) / GRID_WIDTH - center;
            var y:Float = Math.floor(ike / GRID_WIDTH) / GRID_WIDTH - center;
            var z:Float = 0;
            
            // set up vertices
            for (jen in 0...VpB) {
                vertexBuffer.mod((vBall + jen) * FpBV + 0, x * 0.8);
                vertexBuffer.mod((vBall + jen) * FpBV + 1, y * 0.8);
                vertexBuffer.mod((vBall + jen) * FpBV + 2, z);
            }

            // set up indices
            indexBuffer.mod(ike * IpB + 0, ike * VpB + 0);
            indexBuffer.mod(ike * IpB + 1, ike * VpB + 1);
            indexBuffer.mod(ike * IpB + 2, ike * VpB + 2);
            indexBuffer.mod(ike * IpB + 3, ike * VpB + 0);
            indexBuffer.mod(ike * IpB + 4, ike * VpB + 2);
            indexBuffer.mod(ike * IpB + 5, ike * VpB + 3);
        }

        var extensions = ['OES_texture_float', 'OES_standard_derivatives', 'OES_texture_float_linear'];
        program = new Program(vertShader, fragShader, extensions);
    }

    override function update():Void {
        time += 0.1;

        // metaballTexture.image.setPixel(Std.random(metaballTexture.image.width), Std.random(metaballTexture.image.height), 0x0);
        // metaballTexture.update();
        
        bodyTransform.appendRotation(0.1, Vector4.Z_AXIS);

        pool.update(0.1);

        /*
        var str:String = '';
        for (ike in 0...pool.size) {
            var val:Float = pool.getHeightAtIndex(ike);
            if (val < 0) str += '-';
            else if (val == 0) str += ' ';
            else if (val < 0.5) str += 'o';
            else str += '•';
        }
        trace('|$str|');
        */

        for (ike in 0...GRID_WIDTH) {
            for (jen in 0...GRID_WIDTH) {
                if (cavity[ike][jen] != null) {
                    var size:Float = 2 / GRID_WIDTH;
                    var vBall:Int = (ike * GRID_WIDTH + jen) * VpB;
                    for (ken in 0...VpB) {
                        vertexBuffer.mod((vBall + ken) * FpBV + 5, size);
                        vertexBuffer.mod((vBall + ken) * FpBV + 6, 1);
                    }
                } else if (phases[ike][jen] != null) {
                    var size:Float = (pool.getHeightAtIndex(phases[ike][jen]) * 1.0 + 1.9);
                    size += Math.max(0, Math.sin(twitches[ike][jen] * time) * 0.3);
                    size /= GRID_WIDTH;
                    var vBall:Int = (ike * GRID_WIDTH + jen) * VpB;
                    for (ken in 0...VpB) {
                        vertexBuffer.mod((vBall + ken) * FpBV + 5, size);
                    }
                }
            }
        }

        vertexBuffer.upload();
        indexBuffer.upload();
    }

    override function draw():Void {
        program.use();
        program.setBlendFactors(BlendFactor.ONE, BlendFactor.ONE);
        program.setDepthTest(false);

        program.setMatrix4('uBodyMat', bodyTransform); // uBodyMat contains the body's matrix
        program.setMatrix4('uCameraMat', cameraTransform); // uCameraMat contains the camera matrix
        
        program.setTexture('uSampler', metaballTexture); // uSampler contains our metaballTexture
        
        program.setVertexBuffer('aPos',     vertexBuffer, 0, 3); // aPos contains x,y,z
        program.setVertexBuffer('aCorner',  vertexBuffer, 3, 2); // aCorner contains h,v
        program.setVertexBuffer('aScale',   vertexBuffer, 5, 1); // aScale contains s
        program.setVertexBuffer('aCav',     vertexBuffer, 6, 1); // aCav contains c

        program.setRenderTarget(rtt.renderTarget);
        program.clear(new Vec4(0, 0, 0, 1));
        program.draw(indexBuffer, 0, TpB * NUM_BALLS);

        program.setVertexBuffer('aPos',     null, 0, 3);
        program.setVertexBuffer('aCorner',  null, 3, 2);
        program.setVertexBuffer('aScale',   null, 5, 1);
        program.setVertexBuffer('aCav',     null, 6, 1);

        program.setTexture('uSampler', null);
    }
}
