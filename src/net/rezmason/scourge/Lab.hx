package net.rezmason.scourge;

import openfl.Assets.*;
import flash.Vector;
import flash.display.Stage;
import flash.geom.Matrix3D;
import flash.geom.Vector3D;

import net.rezmason.gl.*;
import net.rezmason.gl.Data;

import net.rezmason.scourge.waves.WavePool;
import net.rezmason.scourge.waves.Ripple;
import net.rezmason.scourge.waves.WaveFunctions;

import net.rezmason.utils.Zig;

class Lab {

    var stage:Stage;
    var glSys:GLSystem;
    var glFlow:GLFlowControl;
    var metaballSystem:MetaballSystem;
    var postSystem:PostSystem;

    public function new(stage:Stage):Void {
        this.stage = stage;
        glSys = new GLSystem();
        glFlow = glSys.getFlowControl();
        glFlow.onConnect = onConnect;
        glFlow.connect();
    }

    function onConnect():Void {
        metaballSystem = new MetaballSystem(glSys, stage.stageWidth, stage.stageHeight);
        metaballSystem.loadSig.add(onLoaded);
        
        postSystem = new PostSystem(glSys, stage.stageWidth, stage.stageHeight, metaballSystem);
        postSystem.loadSig.add(onLoaded);
        
        metaballSystem.init();
        postSystem.init();
    }

    function onLoaded():Void {
        if (metaballSystem.ready && postSystem.ready) {
            glFlow.onRender = onRender;
        }
    }

    function onRender(w:Int, h:Int):Void {
        metaballSystem.render();
        postSystem.render();
    }

    public static function makeExtensions(glSys:GLSystem):String {
        var str = '';
        #if js
            var extensions = [];

            glSys.enableExtension("OES_texture_float");
            extensions.push('#extension GL_OES_texture_float : enable');

            glSys.enableExtension("OES_standard_derivatives");
            extensions.push('#extension GL_OES_standard_derivatives : enable');

            glSys.enableExtension("OES_float_linear");
            extensions.push('#extension GL_OES_float_linear : enable');

            str = '${extensions.join("\n")}\nprecision mediump float;';
        #end
        return str;
    }
}

class LabSystem {
    public var loadSig:Zig<Void->Void>;
    public var ready:Bool;
    var glSys:GLSystem;
    var width:Int;
    var height:Int;
    public function new(glSys:GLSystem, width:Int, height:Int):Void {
        this.glSys = glSys;
        this.width = width;
        this.height = height;
        loadSig = new Zig();
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

    public var buffer:OutputBuffer;

    var vertBuffer:VertexBuffer;
    var indexBuffer:IndexBuffer;

    var color:Array<Float>;
    var light:Array<Float>;
    var params:Array<Float>;
    var params2:Array<Float>;

    var lightVector:Vector3D;
    var globMat:Matrix3D;
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

        lightVector = new Vector3D(1, 1, 1);
        lightVector.normalize();
        light = [lightVector.x, lightVector.y, lightVector.z, lightVector.w];

        globMat = new Matrix3D();
        
        metaballTexture = cast(metaballSystem.buffer, TextureOutputBuffer).texture;
        globTexture = glSys.createBitmapDataTexture(getBitmapData('metaballs/glob.png'));

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

                float height = texture2D(uMetaballSampler, vUV).b;

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

        var vertices:VertexArray = new VertexArray(VpB * FpV);
        var vert = [
            -1,-1,0,0,1,
            -1, 1,0,0,0,
             1, 1,0,1,0,
             1,-1,0,1,1,
        ];
        for (ike in 0...VpB * FpV) vertices[ike] = vert[ike];
        vertBuffer = glSys.createVertexBuffer(VpB, FpV);
        vertBuffer.uploadFromVector(vertices, 0, VpB);

        var indices:IndexArray = new IndexArray(6);
        var ind = [
            0, 1, 2,
            0, 2, 3,
        ];
        for (ike in 0...6) indices[ike] = ind[ike];
        indexBuffer = glSys.createIndexBuffer(6);
        indexBuffer.uploadFromVector(indices, 0, 6);

        program = glSys.createProgram(vertShader, fragShader);
        if (program.loaded) onProgramLoaded();
        else program.onLoad = onProgramLoaded;
    }

    function onProgramLoaded():Void {
        ready = true;
        loadSig.dispatch();
    }

    override function update():Void {
        time += 0.05;

        globMat.identity();
        globMat.appendTranslation(-0.5, -0.5, -0.0);
        globMat.appendRotation(time, Vector3D.Z_AXIS);
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
        
        program.setVertexBufferAt('aPos',     vertBuffer, 0, 3); // aPos contains x,y,z
        program.setVertexBufferAt('aUV',      vertBuffer, 3, 2); // aUV contains u,v

        glSys.start(buffer);
        glSys.clear(0xFF000000);
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

    inline static var FpBV:Int = 3 + 2 + 1 + 2; // floats per ball vertex
    inline static var VpB:Int = 4; // vertices per ball
    inline static var IpB:Int = 6; // indices per ball
    inline static var TpB:Int = 2; // triangles per ball

    var texture:Texture;
    var program:Program;

    var bodyTransform:Matrix3D;
    var cameraTransform:Matrix3D;

    public var buffer:OutputBuffer;

    var phases:Array<Array<Null<Int>>>;
    var twitches:Array<Array<Null<Float>>>;

    var vertices:VertexArray;
    var vertBuffer:VertexBuffer;
    var indices:IndexArray;
    var indexBuffer:IndexBuffer;

    var time:Float;

    var pool:WavePool;

    override public function init():Void {

        pool = new WavePool(1);
        pool.addRipple(new Ripple(WaveFunctions.bolus, 0.5, 5., 1.0, 2, true));

        time = 0;

        glSys.enableExtension("OES_texture_float"); // THIS IS NEEDED for all textures to be floating point
        texture = glSys.createBitmapDataTexture(getBitmapData('metaballs/metaball.png'));

        bodyTransform = new Matrix3D();
        cameraTransform = new Matrix3D();
        cameraTransform.rawData = Vector.ofArray(cast [2,0,0,0,0,2,0,0,0,-0,2,1,0,0,0,1]);

        buffer = glSys.createTextureOutputBuffer();
        buffer.resize(width, height);

        var vertShader = '
            attribute vec3 aPos;
            attribute vec2 aCorner;
            attribute float aScale;
            attribute vec2 aUV;

            uniform mat4 uCameraMat;
            uniform mat4 uBodyMat;

            varying vec2 vUV;

            void main(void) {
                vec4 pos = uBodyMat * vec4(aPos, 1.0);
                pos = uCameraMat * pos;
                pos.xy += ((vec4(aCorner.x, aCorner.y, 1.0, 1.0)).xy) * aScale;

                vUV = aUV;

                pos.z = clamp(pos.z, 0.0, 1.0);
                gl_Position = pos;
            }
        ';
        var fragShader = '
            varying vec2 vUV;

            uniform sampler2D uSampler;
            
            void main(void) {
                gl_FragColor = texture2D(uSampler, vUV);
            }
        ';

        fragShader = Lab.makeExtensions(glSys) + fragShader;

        phases = [];
        twitches = [];
        for (ike in 0...GRID_WIDTH) {
            phases.push([]);
            twitches.push([]);
        }
        vertices = new VertexArray(NUM_BALLS * VpB * FpBV);
        indices = new IndexArray(NUM_BALLS * IpB);

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

        pool.size = Std.int(GRID_WIDTH);

        var center:Float = (GRID_WIDTH - 1) / (2 * GRID_WIDTH);

        var ballVertTemplate:Array<Float> = [
            0, 0, 0, -1, -1, 0, 0, 1, 
            0, 0, 0, -1,  1, 0, 0, 0, 
            0, 0, 0,  1,  1, 0, 1, 0, 
            0, 0, 0,  1, -1, 0, 1, 1, 
        ];

        var ballIndexTemplate:Array<Int> = [
            0, 1, 2, 0, 3, 4,
        ];

        for (ike in 0...NUM_BALLS) {
            var vBall:Int = ike * VpB * FpBV;
            for (jen in 0...FpBV * VpB) {
                vertices[vBall + jen] = ballVertTemplate[jen];
            }
        }

        for (ike in 0...NUM_BALLS) {

            var vBall:Int = ike * VpB;

            var x:Float = (ike % GRID_WIDTH) / GRID_WIDTH - center;
            var y:Float = Math.floor(ike / GRID_WIDTH) / GRID_WIDTH - center;
            var z:Float = 0;
            
            // set up vertices
            for (jen in 0...VpB) {
                vertices[(vBall + jen) * FpBV + 0] = x * 0.8;
                vertices[(vBall + jen) * FpBV + 1] = y * 0.8;
                vertices[(vBall + jen) * FpBV + 2] = z;
            }

            // set up indices
            indices[ike * IpB + 0] = ike * VpB + 0;
            indices[ike * IpB + 1] = ike * VpB + 1;
            indices[ike * IpB + 2] = ike * VpB + 2;
            indices[ike * IpB + 3] = ike * VpB + 0;
            indices[ike * IpB + 4] = ike * VpB + 2;
            indices[ike * IpB + 5] = ike * VpB + 3;
        }

        vertBuffer = glSys.createVertexBuffer(NUM_BALLS * VpB, FpBV);
        indexBuffer = glSys.createIndexBuffer(NUM_BALLS * IpB);

        program = glSys.createProgram(vertShader, fragShader);
        if (program.loaded) onProgramLoaded();
        else program.onLoad = onProgramLoaded;
    }

    function onProgramLoaded():Void {
        ready = true;
        loadSig.dispatch();
    }

    override function update():Void {
        time += 0.2;
        
        //bodyTransform.appendRotation(1, Vector3D.Z_AXIS);

        pool.update(0.2);

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
                if (phases[ike][jen] != null) {
                    var size:Float = (pool.getHeightAtIndex(phases[ike][jen]) * 0.4 + 2.0);
                    size += Math.sin(twitches[ike][jen] * time) * 0.25;
                    size /= GRID_WIDTH;
                    var vBall:Int = (ike * GRID_WIDTH + jen) * VpB;
                    for (ken in 0...VpB) vertices[(vBall + ken) * FpBV + 5] = size;
                }
            }
        }

        vertBuffer.uploadFromVector(vertices, 0, NUM_BALLS * VpB);
        indexBuffer.uploadFromVector(indices, 0, NUM_BALLS * IpB);
    }

    override function draw():Void {
        glSys.setProgram(program);
        glSys.setBlendFactors(BlendFactor.ONE, BlendFactor.ONE);
        glSys.setDepthTest(false);

        program.setProgramConstantsFromMatrix('uBodyMat', bodyTransform); // uBodyMat contains the body's matrix
        program.setProgramConstantsFromMatrix('uCameraMat', cameraTransform); // uCameraMat contains the camera matrix
        
        program.setTextureAt('uSampler', texture); // uSampler contains our texture
        
        program.setVertexBufferAt('aPos',     vertBuffer, 0, 3); // aPos contains x,y,z
        program.setVertexBufferAt('aCorner',  vertBuffer, 3, 2); // aCorner contains h,v
        program.setVertexBufferAt('aScale',   vertBuffer, 5, 1); // aScale contains s
        program.setVertexBufferAt('aUV',      vertBuffer, 6, 2); // aUV contains u,v

        glSys.start(buffer);
        glSys.clear(0xFF000000);
        glSys.draw(indexBuffer, 0, TpB * NUM_BALLS);
        glSys.finish();

        program.setVertexBufferAt('aPos',     null, 0, 3);
        program.setVertexBufferAt('aCorner',  null, 3, 2);
        program.setVertexBufferAt('aScale',   null, 5, 1);
        program.setVertexBufferAt('aUV',      null, 6, 2);

        program.setTextureAt('uSampler', null); // uSampler contains our texture
    }
}
