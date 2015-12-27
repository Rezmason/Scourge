package net.rezmason.scourge;

import haxe.io.BytesOutput;
import lime.Assets.*;
import net.rezmason.gl.*;
import net.rezmason.gl.GLTypes;
import net.rezmason.math.FelzenszwalbSDF;
import net.rezmason.scourge.waves.Ripple;
import net.rezmason.scourge.waves.WaveFunctions;
import net.rezmason.scourge.waves.WavePool;
import net.rezmason.utils.HalfFloatUtil;
import net.rezmason.utils.Zig;

class Lab {

    var width:Int;
    var height:Int;
    var glSys:GLSystem;
    var metaballSystem:MetaballSystem;
    var postSystem:PostSystem;
    var dataSystem:DataSystem;

    public function new(width:Int, height:Int):Void {
        this.width = width;
        this.height = height;
        glSys = new GLSystem();
        glSys.onConnected = onConnect;
        glSys.connect();
    }

    function onConnect():Void {
        metaballSystem = new MetaballSystem(glSys, width, height);
        postSystem = new PostSystem(glSys, width, height, metaballSystem);
        metaballSystem.init();
        postSystem.init();
        dataSystem = new DataSystem(glSys, width, height);
        dataSystem.init();
    }

    public function render():Void {
        /*
        if (glSys.connected && metaballSystem.ready && postSystem.ready) {
            metaballSystem.render();
            postSystem.render();
        }
        /**/
        //*
        if (glSys.connected && dataSystem.ready) {
            dataSystem.render();
        }
        /**/
    }

    public static function makeExtensions(glSys:GLSystem):String {
        var str = '';
        #if js
            var extensions = [];

            glSys.enableExtension("OES_texture_float");
            extensions.push('#extension GL_OES_texture_float : enable');

            glSys.enableExtension("OES_standard_derivatives");
            extensions.push('#extension GL_OES_standard_derivatives : enable');

            glSys.enableExtension("OES_texture_float_linear");
            extensions.push('#extension GL_OES_texture_float_linear : enable');

            str = '${extensions.join("\n")}\nprecision mediump float;';
        #end
        return str;
    }
}

class LabSystem {
    public var ready:Bool;
    var glSys:GLSystem;
    var width:Int;
    var height:Int;
    public function new(glSys:GLSystem, width:Int, height:Int):Void {
        this.glSys = glSys;
        this.width = width;
        this.height = height;
        ready = false;
    }

    public function init():Void {

    }

    function update():Void {}
    function draw():Void {}

    public function render():Void {
        if (ready) {
            update();
            draw();
        }
    }
}

class PostSystem extends LabSystem {

    inline static var FpV:Int = 3 + 2; // floats per vertex
    inline static var VpB:Int = 4; // vertices per billboard
    
    var metaballSystem:MetaballSystem;

    var metaballTexture:Texture;
    var globTexture:Texture;
    var program:Program;

    var buffer:OutputBuffer;

    var vertexBuffer:VertexBuffer;
    var indexBuffer:IndexBuffer;

    var color:Array<Float>;
    var light:Array<Float>;
    var params:Array<Float>;
    var params2:Array<Float>;

    var lightVector:Vector4;
    var globMat:Matrix4;
    var time:Float;

    public function new(glSys:GLSystem, width:Int, height:Int, metaballSystem:MetaballSystem):Void {
        super(glSys, width, height);
        this.metaballSystem = metaballSystem;
    }

    override public function init():Void {

        time = 0;
        var heightThreshold:Float = 0.7;
        var heightEnvelope:Float = 0.02;

        var lower:Float = heightThreshold - heightEnvelope;
        var upper:Float = heightThreshold + heightEnvelope;

        var innerGlow:Float = 0.8;
        var outerGlow:Float = 0.2;
        var shine:Float = 0.3;

        var nudge:Float = 0.005;

        params = [lower, upper, innerGlow, shine];
        params2 = [nudge, outerGlow, 0, 0];
        color = [0.4, 0.9, 0.1, 1.0];

        lightVector = new Vector4(1, 1, 1);
        lightVector.normalize();
        light = [lightVector.x, lightVector.y, lightVector.z, lightVector.w];

        globMat = new Matrix4();
        
        metaballTexture = cast(metaballSystem.buffer, TextureOutputBuffer).texture;
        globTexture = glSys.createImageTexture(getImage('metaballs/glob.png'));

        buffer = glSys.viewportOutputBuffer;
        buffer.resize(width, height);

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

        fragShader = Lab.makeExtensions(glSys) + fragShader;

        vertexBuffer = glSys.createVertexBuffer(VpB, FpV);
        var vert = [
            -1, -1, 0, 0, 1,
            -1,  1, 0, 0, 0,
             1,  1, 0, 1, 0,
             1, -1, 0, 1, 1,
        ];
        for (ike in 0...VpB * FpV) vertexBuffer.mod(ike, vert[ike]);
        vertexBuffer.upload();

        indexBuffer = glSys.createIndexBuffer(6);
        var ind = [
            0, 1, 2,
            0, 2, 3,
        ];
        for (ike in 0...6) indexBuffer.mod(ike, ind[ike]);
        indexBuffer.upload();

        program = glSys.createProgram(vertShader, fragShader);
        ready = true;
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
        glSys.setProgram(program);
        glSys.setBlendFactors(BlendFactor.ONE, BlendFactor.ONE);
        glSys.setDepthTest(false);

        program.setTextureAt('uMetaballSampler', metaballTexture); // uMetaballSampler contains our metaballTexture
        program.setTextureAt('uGlobSampler', globTexture, 1); // uGlobSampler contains our glob texture
        program.setFourProgramConstants('uParams', params);
        program.setFourProgramConstants('uParams2', params2);
        program.setFourProgramConstants('uColor', color);
        program.setFourProgramConstants('uLight', light);
        program.setProgramConstantsFromMatrix('uGlobMat', globMat);
        
        program.setVertexBufferAt('aPos',     vertexBuffer, 0, 3); // aPos contains x,y,z
        program.setVertexBufferAt('aUV',      vertexBuffer, 3, 2); // aUV contains u,v

        glSys.start(buffer);
        glSys.clear(0, 0, 0);
        glSys.draw(indexBuffer, 0, 2);
        glSys.finish();

        program.setVertexBufferAt('aPos',     null, 0, 3);
        program.setVertexBufferAt('aUV',      null, 3, 2);

        program.setTextureAt('uMetaballSampler', null);
        program.setTextureAt('uGlobSampler', null, 1);
    }
}

class MetaballSystem extends LabSystem {

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

    public var buffer:OutputBuffer;

    var phases:Array<Array<Null<Int>>>;
    var cavity:Array<Array<Null<Int>>>;
    var twitches:Array<Array<Null<Float>>>;

    var vertexBuffer:VertexBuffer;
    var indexBuffer:IndexBuffer;

    var time:Float;

    var pool:WavePool;

    override public function init():Void {

        pool = new WavePool(1);
        pool.addRipple(new Ripple(WaveFunctions.bolus, 0.5, 5., 1.0, 2, true));

        time = 0;

        Lab.makeExtensions(glSys); // THIS IS NEEDED for all textures to be floating point
        metaballTexture = glSys.createImageTexture(getImage('metaballs/metaball.png'));

        bodyTransform = new Matrix4();
        cameraTransform = new Matrix4();
        cameraTransform.rawData = cast [2,0,0,0,0,2,0,0,0,-0,2,1,0,0,0,1];

        buffer = glSys.createTextureOutputBuffer();
        buffer.resize(width, height);

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

        fragShader = Lab.makeExtensions(glSys) + fragShader;

        phases = [];
        cavity = [];
        twitches = [];
        for (ike in 0...GRID_WIDTH) {
            cavity.push([]);
            phases.push([]);
            twitches.push([]);
        }
        
        vertexBuffer = glSys.createVertexBuffer(NUM_BALLS * VpB, FpBV);
        indexBuffer = glSys.createIndexBuffer(NUM_BALLS * IpB);

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

        program = glSys.createProgram(vertShader, fragShader);
        ready = true;
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
        glSys.setProgram(program);
        glSys.setBlendFactors(BlendFactor.ONE, BlendFactor.ONE);
        glSys.setDepthTest(false);

        program.setProgramConstantsFromMatrix('uBodyMat', bodyTransform); // uBodyMat contains the body's matrix
        program.setProgramConstantsFromMatrix('uCameraMat', cameraTransform); // uCameraMat contains the camera matrix
        
        program.setTextureAt('uSampler', metaballTexture); // uSampler contains our metaballTexture
        
        program.setVertexBufferAt('aPos',     vertexBuffer, 0, 3); // aPos contains x,y,z
        program.setVertexBufferAt('aCorner',  vertexBuffer, 3, 2); // aCorner contains h,v
        program.setVertexBufferAt('aScale',   vertexBuffer, 5, 1); // aScale contains s
        program.setVertexBufferAt('aCav',     vertexBuffer, 6, 1); // aCav contains c

        glSys.start(buffer);
        glSys.clear(0, 0, 0);
        glSys.draw(indexBuffer, 0, TpB * NUM_BALLS);
        glSys.finish();

        program.setVertexBufferAt('aPos',     null, 0, 3);
        program.setVertexBufferAt('aCorner',  null, 3, 2);
        program.setVertexBufferAt('aScale',   null, 5, 1);
        program.setVertexBufferAt('aCav',     null, 6, 1);

        program.setTextureAt('uSampler', null);
    }
}

class DataSystem extends LabSystem {

    inline static var FLOATS_PER_VERTEX:Int = 2 + 2;
    inline static var TOTAL_VERTICES:Int = 4;
    inline static var TOTAL_TRIANGLES:Int = 2;
    inline static var TOTAL_INDICES:Int = TOTAL_TRIANGLES * 3;
    
    var dataTexture:Texture;
    var program:Program;

    var buffer:OutputBuffer;

    var vertexBuffer:VertexBuffer;
    var indexBuffer:IndexBuffer;

    override public function init():Void {

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

        dataTexture = glSys.createHalfFloatTexture(width, height, output.getBytes());

        buffer = glSys.viewportOutputBuffer;
        buffer.resize(width, height);

        vertexBuffer = glSys.createVertexBuffer(TOTAL_VERTICES, FLOATS_PER_VERTEX);
        var vertices = [
            -1, -1,  0,  0, 
            -1,  1,  0,  1, 
             1, -1,  1,  0, 
             1,  1,  1,  1, 
        ];
        for (ike in 0...vertices.length) vertexBuffer.mod(ike, vertices[ike]);
        vertexBuffer.upload();

        indexBuffer = glSys.createIndexBuffer(TOTAL_INDICES);
        var ind = [0, 1, 2, 1, 2, 3,];
        for (ike in 0...TOTAL_INDICES) indexBuffer.mod(ike, ind[ike]);
        indexBuffer.upload();

        var extensions = Lab.makeExtensions(glSys);
        
        var vertShader = extensions + '
            attribute vec2 aPos;
            attribute vec2 aUV;
            varying vec2 vUV;

            void main(void) {
                vUV = aUV;
                gl_Position = vec4(aPos, 0., 1.0);
            }

            '
            ;
        
        var fragShader = extensions + '
            varying vec2 vUV;
            uniform sampler2D uDataSampler;

            void main(void) {
                gl_FragColor = texture2D(uDataSampler, vUV);
            }
            ';

        program = glSys.createProgram(vertShader, fragShader);
        ready = true;
    }

    override function update():Void {}

    override function draw():Void {
        glSys.setProgram(program);
        glSys.setBlendFactors(BlendFactor.ONE, BlendFactor.ONE);
        glSys.setDepthTest(false);

        program.setTextureAt('uDataSampler', dataTexture, 1); // uDataSampler contains our data texture
        program.setVertexBufferAt('aPos', vertexBuffer, 0, 2);
        program.setVertexBufferAt('aUV',  vertexBuffer, 2, 2);

        glSys.start(buffer);
        glSys.clear(0, 0, 0);
        glSys.draw(indexBuffer, 0, TOTAL_TRIANGLES);
        glSys.finish();
        
        program.setTextureAt('uDataSampler', null, 1);
        program.setVertexBufferAt('aPos', null, 0, 2);
        program.setVertexBufferAt('aUV',  null, 2, 2);
    }
}
