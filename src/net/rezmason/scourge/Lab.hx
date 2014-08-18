package net.rezmason.scourge;

import openfl.Assets.*;
import flash.Vector;
import flash.display.Stage;
import flash.geom.Matrix3D;
import flash.geom.Vector3D;

import net.rezmason.gl.utils.*;
import net.rezmason.gl.*;
import net.rezmason.gl.Data;

import net.rezmason.utils.Zig;

class Lab {

    var utils:UtilitySet;
    var metaballSystem:MetaballSystem;
    var postSystem:PostSystem;

    public function new(utils:UtilitySet, stage:Stage):Void {
        this.utils = utils;
        var width:Int = stage.stageWidth;
        var height:Int = stage.stageHeight;

        metaballSystem = new MetaballSystem(utils, width, height);
        metaballSystem.loadSig.add(onLoaded);
        postSystem = new PostSystem(utils, width, height, metaballSystem);
        postSystem.loadSig.add(onLoaded);
        
        metaballSystem.init();
        postSystem.init();
    }

    function onLoaded():Void {
        if (metaballSystem.ready && postSystem.ready) {
            utils.drawUtil.addRenderCall(onRender);
        }
    }

    function onRender(w:Int, h:Int):Void {
        metaballSystem.render();
        postSystem.render();
    }

    public static function makeExtensions(utils:UtilitySet):String {
        var str = '';
        #if js
            var extensions = [];

            utils.programUtil.enableExtension("OES_standard_derivatives");
            extensions.push('#extension GL_OES_standard_derivatives : enable');

            utils.programUtil.enableExtension("OES_float_linear");
            extensions.push('#extension GL_OES_float_linear : enable');

            str = '${extensions.join("\n")}\nprecision mediump float;';
        #end
        return str;
    }
}

class LabSystem {
    public var loadSig:Zig<Void->Void>;
    public var ready:Bool;
    var utils:UtilitySet;
    var width:Int;
    var height:Int;
    public function new(utils:UtilitySet, width:Int, height:Int):Void {
        this.utils = utils;
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

    inline static var FpBV:Int = 3 + 2 + 2 + 1; // floats per ball vertex
    inline static var VpB:Int = 4; // vertices per ball
    
    var metaballSystem:MetaballSystem;

    var aPos:AttribsLocation;
    var aUV:AttribsLocation;
    var uSampler:UniformLocation;
    var uParams:UniformLocation;
    
    var texture:Texture;
    var program:Program;

    public var buffer:OutputBuffer;

    var phases:Array<Null<Float>>;

    var vertBuffer:VertexBuffer;
    var indexBuffer:IndexBuffer;

    var t:Float;

    public function new(utils:UtilitySet, width:Int, height:Int, metaballSystem:MetaballSystem):Void {
        super(utils, width, height);
        this.metaballSystem = metaballSystem;
        
    }

    override public function init():Void {

        t = 0;
        
        texture = metaballSystem.buffer.texture;

        buffer = utils.drawUtil.createOutputBuffer(VIEWPORT);
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

            uniform sampler2D uSampler;
            uniform vec4 uParams;

            void main(void) {
                float inv = 1.0 - texture2D(uSampler, vUV).b;
                float brightness = 1.0 - inv * inv;
                
                float glob = brightness * 11.0 - 9.5;
                
                gl_FragColor = glob * vec4(0.2, 1.0, 0.2, 1.0);
            }
        ';

        fragShader = Lab.makeExtensions(utils) + fragShader;

        utils.programUtil.loadProgram(vertShader, fragShader, onProgramLoaded);

        // Create geometry

        var vertices:VertexArray = new VertexArray(VpB * FpBV);
        var vert = [
            -1,-1,0,0,1,0,0,1,
            -1, 1,0,0,0,0,0,1,
             1, 1,0,1,0,0,0,1,
             1,-1,0,1,1,0,0,1,
        ];
        for (ike in 0...VpB * FpBV) vertices[ike] = vert[ike];
        vertBuffer = utils.bufferUtil.createVertexBuffer(VpB, FpBV);
        vertBuffer.uploadFromVector(vertices, 0, VpB);

        var indices:IndexArray = new IndexArray(6);
        var ind = [
            0, 1, 2,
            0, 2, 3,
        ];
        for (ike in 0...6) indices[ike] = ind[ike];
        indexBuffer = utils.bufferUtil.createIndexBuffer(6);
        indexBuffer.uploadFromVector(indices, 0, 6);
    }

    function onProgramLoaded(program:Program):Void {
        this.program = program;

        // Connect to shader

        aPos     = utils.programUtil.getAttribsLocation(program, 'aPos'    );
        aUV      = utils.programUtil.getAttribsLocation(program, 'aUV'     );
        
        uSampler   = utils.programUtil.getUniformLocation(program, 'uSampler'  );
        uParams    = utils.programUtil.getUniformLocation(program, 'uParams');
        
        utils.programUtil.setFourProgramConstants(this.program, uParams, [0, 0, 0, 0]);
        ready = true;
        loadSig.dispatch();
    }

    override function update():Void {
        t += 0.1;
    }

    override function draw():Void {
        //*
        utils.programUtil.setProgram(program);
        utils.programUtil.setBlendFactors(BlendFactor.ONE, BlendFactor.ONE);
        utils.programUtil.setDepthTest(false);

        utils.programUtil.setTextureAt(program, uSampler, texture); // uSampler contains our texture

        utils.programUtil.setVertexBufferAt(program, aPos,     vertBuffer, 0, 3); // aPos contains x,y,z
        utils.programUtil.setVertexBufferAt(program, aUV,      vertBuffer, 3, 2); // aUV contains u,v

        utils.drawUtil.setOutputBuffer(buffer);
        utils.drawUtil.clear(0xFF000000);
        utils.drawUtil.drawTriangles(indexBuffer, 0, 2);
        utils.drawUtil.finishOutputBuffer(buffer);

        utils.programUtil.setVertexBufferAt(program, aPos,     null, 0, 3); // aPos contains x,y,z
        utils.programUtil.setVertexBufferAt(program, aUV,      null, 3, 2); // aUV contains u,v
        /**/
    }
}

class MetaballSystem extends LabSystem {

    inline static var GRID_WIDTH:Int = 10;
    inline static var NUM_BALLS:Int = GRID_WIDTH * GRID_WIDTH;

    inline static var FpBV:Int = 3 + 2 + 1 + 2; // floats per ball vertex
    inline static var VpB:Int = 4; // vertices per ball
    inline static var IpB:Int = 6; // indices per ball
    inline static var TpB:Int = 2; // triangles per ball

    var aPos:AttribsLocation;
    var aCorner:AttribsLocation;
    var aScale:AttribsLocation;
    var aUV:AttribsLocation;
    
    var uSampler:UniformLocation;
    var uParams:UniformLocation;
    var uCameraMat:UniformLocation;
    var uBodyMat:UniformLocation;

    var texture:Texture;
    var program:Program;

    var bodyTransform:Matrix3D;
    var cameraTransform:Matrix3D;

    public var buffer:OutputBuffer;

    var phases:Array<Null<Float>>;

    var shapeVertices:VertexArray;
    var shapeBuffer:VertexBuffer;
    var indices:IndexArray;
    var indexBuffer:IndexBuffer;

    var t:Float;

    override public function init():Void {

        t = 0;

        texture = utils.textureUtil.createBitmapDataTexture(getBitmapData('metaballs/metaball.png'));

        bodyTransform = new Matrix3D();
        cameraTransform = new Matrix3D();
        cameraTransform.rawData = Vector.ofArray(cast [2,0,0,0,0,2,0,0,0,-0,2,1,0,0,0,1]);

        buffer = utils.drawUtil.createOutputBuffer(TEXTURE);
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
            uniform vec4 uParams;

            void main(void) {
                gl_FragColor = texture2D(uSampler, vUV);
            }
        ';

        fragShader = Lab.makeExtensions(utils) + fragShader;

        utils.programUtil.loadProgram(vertShader, fragShader, onProgramLoaded);

        // Create geometry

        phases = [];
        shapeVertices = new VertexArray(NUM_BALLS * VpB * FpBV);
        indices = new IndexArray(NUM_BALLS * IpB);

        var drunkX:Int = Std.int(GRID_WIDTH / 2);
        var drunkY:Int = Std.int(GRID_WIDTH / 2);
        for (ike in 0...Std.int(GRID_WIDTH * 2.5)) {
            var index:Int = drunkX + drunkY * GRID_WIDTH;
            phases[index] = 0;
            if (Std.random(2) == 0) {
                drunkX = Std.int(Math.min(GRID_WIDTH - 1, Math.max(0, drunkX + Std.random(2) * 2 - 1)));
            } else {
                drunkY = Std.int(Math.min(GRID_WIDTH - 1, Math.max(0, drunkY + Std.random(2) * 2 - 1)));
            }
        }

        var center:Float = (GRID_WIDTH - 1) / (2 * GRID_WIDTH);

        for (ike in 0...NUM_BALLS) {

            var vBall:Int = ike * VpB;

            var x:Float = (ike % GRID_WIDTH) / GRID_WIDTH - center;
            var y:Float = Math.floor(ike / GRID_WIDTH) / GRID_WIDTH - center;
            var z:Float = 0;
            
            if (phases[ike] == 0) phases[ike] = Math.random() * Math.PI * 2;

            // set up vertices
            for (jen in 0...VpB) {
                shapeVertices[(vBall + jen) * FpBV + 0] = x * 0.8;
                shapeVertices[(vBall + jen) * FpBV + 1] = y * 0.8;
                shapeVertices[(vBall + jen) * FpBV + 2] = z;
                shapeVertices[(vBall + jen) * FpBV + 5] = 0;
            }

            shapeVertices[(vBall + 0) * FpBV + 3] = -1;
            shapeVertices[(vBall + 1) * FpBV + 3] = -1;
            shapeVertices[(vBall + 2) * FpBV + 3] =  1;
            shapeVertices[(vBall + 3) * FpBV + 3] =  1;

            shapeVertices[(vBall + 0) * FpBV + 4] = -1;
            shapeVertices[(vBall + 1) * FpBV + 4] =  1;
            shapeVertices[(vBall + 2) * FpBV + 4] =  1;
            shapeVertices[(vBall + 3) * FpBV + 4] = -1;

            shapeVertices[(vBall + 0) * FpBV + 6] =  0;
            shapeVertices[(vBall + 1) * FpBV + 6] =  0;
            shapeVertices[(vBall + 2) * FpBV + 6] =  1;
            shapeVertices[(vBall + 3) * FpBV + 6] =  1;

            shapeVertices[(vBall + 0) * FpBV + 7] =  1;
            shapeVertices[(vBall + 1) * FpBV + 7] =  0;
            shapeVertices[(vBall + 2) * FpBV + 7] =  0;
            shapeVertices[(vBall + 3) * FpBV + 7] =  1;

            // set up indices
            indices[ike * IpB + 0] = ike * VpB + 0;
            indices[ike * IpB + 1] = ike * VpB + 1;
            indices[ike * IpB + 2] = ike * VpB + 2;
            indices[ike * IpB + 3] = ike * VpB + 0;
            indices[ike * IpB + 4] = ike * VpB + 2;
            indices[ike * IpB + 5] = ike * VpB + 3;
        }

        shapeBuffer = utils.bufferUtil.createVertexBuffer(NUM_BALLS * VpB, FpBV);
        indexBuffer = utils.bufferUtil.createIndexBuffer(NUM_BALLS * IpB);
    }

    function onProgramLoaded(program:Program):Void {
        this.program = program;

        // Connect to shader

        aPos     = utils.programUtil.getAttribsLocation(program, 'aPos'    );
        aCorner  = utils.programUtil.getAttribsLocation(program, 'aCorner' );
        aScale   = utils.programUtil.getAttribsLocation(program, 'aScale');
        aUV      = utils.programUtil.getAttribsLocation(program, 'aUV'     );
        
        uSampler   = utils.programUtil.getUniformLocation(program, 'uSampler'  );
        uParams    = utils.programUtil.getUniformLocation(program, 'uParams');
        uCameraMat = utils.programUtil.getUniformLocation(program, 'uCameraMat');
        uBodyMat   = utils.programUtil.getUniformLocation(program, 'uBodyMat'  );

        utils.programUtil.setFourProgramConstants(this.program, uParams, [0, 0, 0, 0]);
        ready = true;
        loadSig.dispatch();
    }

    override function update():Void {
        t += 0.1;
        
        //bodyTransform.appendRotation(1, Vector3D.Z_AXIS);

        for (ike in 0...NUM_BALLS) {
            if (phases[ike] == null) continue;
            var vBall:Int = ike * VpB;
            var s:Float = (Math.sin(phases[ike] + t) + 1) * 0.2 + 0.8;
            for (jen in 0...VpB) shapeVertices[(vBall + jen) * FpBV + 5] = s * 2.5 / GRID_WIDTH;
        }

        shapeBuffer.uploadFromVector(shapeVertices, 0, NUM_BALLS * VpB);
        indexBuffer.uploadFromVector(indices, 0, NUM_BALLS * IpB);
    }

    override function draw():Void {
        //*
        utils.programUtil.setProgram(program);
        utils.programUtil.setBlendFactors(BlendFactor.ONE, BlendFactor.ONE);
        utils.programUtil.setDepthTest(false);

        utils.programUtil.setProgramConstantsFromMatrix(program, uBodyMat, bodyTransform); // uBodyMat contains the body's matrix
        utils.programUtil.setProgramConstantsFromMatrix(program, uCameraMat, cameraTransform); // uCameraMat contains the camera matrix
        
        utils.programUtil.setTextureAt(program, uSampler, texture); // uSampler contains our texture

        utils.programUtil.setVertexBufferAt(program, aPos,     shapeBuffer, 0, 3); // aPos contains x,y,z
        utils.programUtil.setVertexBufferAt(program, aCorner,  shapeBuffer, 3, 2); // aCorner contains h,v
        utils.programUtil.setVertexBufferAt(program, aScale,   shapeBuffer, 5, 1); // aScale contains s
        utils.programUtil.setVertexBufferAt(program, aUV,      shapeBuffer, 6, 2); // aUV contains u,v

        utils.drawUtil.setOutputBuffer(buffer);
        utils.drawUtil.clear(0xFF000000);
        utils.drawUtil.drawTriangles(indexBuffer, 0, TpB * NUM_BALLS);
        utils.drawUtil.finishOutputBuffer(buffer);

        utils.programUtil.setVertexBufferAt(program, aPos,     null, 0, 3); // aPos contains x,y,z
        utils.programUtil.setVertexBufferAt(program, aCorner,  null, 3, 2); // aCorner contains h,v
        utils.programUtil.setVertexBufferAt(program, aScale,   null, 5, 1); // aScale contains s
        utils.programUtil.setVertexBufferAt(program, aUV,      null, 6, 2); // aUV contains u,v
        /**/
    }
}
