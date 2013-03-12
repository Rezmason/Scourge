package net.rezmason.scourge.textview;

import com.adobe.utils.AGALMiniAssembler;
import com.adobe.utils.PerspectiveMatrix3D;
import haxe.Timer;
import nme.Assets;
import nme.display.Bitmap;
import nme.display.BitmapData;
import nme.display.Shape;
import nme.display.Stage3D;
import nme.display.Stage;
import nme.display3D.Context3D;
import nme.display3D.Context3DBlendFactor;
import nme.display3D.Context3DCompareMode;
import nme.display3D.Context3DProgramType;
import nme.display3D.Context3DTextureFormat;
import nme.display3D.Context3DVertexBufferFormat;
import nme.display3D.IndexBuffer3D;
import nme.display3D.Program3D;
import nme.display3D.textures.Texture;
import nme.display3D.VertexBuffer3D;
import nme.events.Event;
import nme.events.MouseEvent;
import nme.geom.Matrix3D;
import nme.geom.Matrix;
import nme.geom.Vector3D;
import nme.utils.ByteArray;
import nme.Vector;

enum FuckMode {
    MOUSE;
    PRETTY;
}

typedef BufferSet = {
    var id:Int;
    var colors:VertexBuffer3D;
    var geom:VertexBuffer3D;
    var indices:IndexBuffer3D;
}

class Stage3DFuckbox {

    inline static var TEXTURE_SIZE:Int = 1024;
    inline static var NUM_GEOM_FLOATS_PER_VERTEX:Int = 3; // XYZ
    inline static var NUM_COLOR_FLOATS_PER_VERTEX:Int = 3 + 2 + 1; // RGB UV I
    inline static var NUM_VERTICES_PER_QUAD:Int = 4;
    inline static var NUM_TRIANGLES_PER_QUAD:Int = 2;
    inline static var NUM_INDICES_PER_TRIANGLE:Int = 3;
    inline static var NUM_INDICES_PER_QUAD:Int = NUM_TRIANGLES_PER_QUAD * NUM_INDICES_PER_TRIANGLE;
    inline static var COLOR_RANGE:Int = 6;
    inline static var BUFFER_SIZE:Int = 0xFFFF;

    var stage:Stage;
    var stage3D:Stage3D;

    var mode:FuckMode;

    var mouseBD:BitmapData;
    var mouseBitmap:Bitmap;
    var mouseShape:Shape;

    var projection:PerspectiveMatrix3D;
    var projections:Array<Matrix3D>;
    var cameraMat:Matrix3D;
    var context:Context3D;
    var prettyProgram:Program3D;
    var mouseProgram:Program3D;
    var bufferSets:Array<BufferSet>;
    var texture:Texture;

    public function new(stage:Stage) {
        this.stage = stage;

        stage.addEventListener(Event.RESIZE, configureBuffer);

        mouseBitmap = new Bitmap();
        mouseBitmap.scaleX = mouseBitmap.scaleY = 0.3;
        stage.addChild(mouseBitmap);
        mouseShape = new Shape();
        mouseShape.graphics.beginFill(0xFFFFFF);
        mouseShape.graphics.lineTo(0, 20);
        mouseShape.graphics.lineTo(10, 16);
        mouseShape.graphics.endFill();
        stage.addChild(mouseShape);

        stage3D = stage.stage3Ds[0];
        stage3D.addEventListener(Event.CONTEXT3D_CREATE, onCreate);
        stage3D.requestContext3D();
    }

    function configureBuffer(?event:Event):Void {
        if (context != null) {
            context.configureBackBuffer(stage.stageWidth, stage.stageHeight, 16, true);
            if (mouseBD != null)
            {
                mouseBD.dispose();
            }
            mouseBD = new BitmapData(stage.stageWidth, stage.stageHeight, false, 0x0);
            mouseBitmap.bitmapData = mouseBD;
        }
    }

    function onCreate(event:Event):Void {
        stage3D.removeEventListener(Event.CONTEXT3D_CREATE, onCreate);

        context = stage3D.context3D;
        configureBuffer();
        context.setDepthTest(false, Context3DCompareMode.LESS);

        makeConstants();
        makeTexture();
        makeBufferSets();
        makePrettyProgram();
        makeMouseProgram();

        stage.addEventListener(Event.ENTER_FRAME, renderPretty);
        stage.addEventListener(Event.ENTER_FRAME, update);
        stage.addEventListener(MouseEvent.CLICK, renderMouse);
        stage.addEventListener(MouseEvent.MOUSE_MOVE, checkMouse);
        update();
        renderMouse();
        renderPretty();
    }

    function makeBufferSets():Void {

        bufferSets = [];

        var charQuadChunk:Int = Std.int(BUFFER_SIZE / NUM_VERTICES_PER_QUAD);

        var remainingCharQuads:Int = Constants.NUM_CHARS;
        var startCharQuad:Int = 0;

        var id:Int = 0;
        while (startCharQuad < Constants.NUM_CHARS) {
            var len:Int = remainingCharQuads < charQuadChunk ? remainingCharQuads : charQuadChunk;
            bufferSets.push(makeBufferSet(id, startCharQuad, len));

            startCharQuad += charQuadChunk;
            remainingCharQuads -= charQuadChunk;
            id++;
        }
    }

    function makeBufferSet(id:Int, startCharQuad:Int, numCharQuads:Int):BufferSet {

        flash.Lib.trace(["!", startCharQuad]);

        var numCharVertices:Int = numCharQuads * NUM_VERTICES_PER_QUAD;
        var numCharIndices:Int = numCharQuads * NUM_INDICES_PER_QUAD;

        var geomBuffer:VertexBuffer3D = context.createVertexBuffer(numCharVertices, NUM_GEOM_FLOATS_PER_VERTEX);
        var colorBuffer:VertexBuffer3D = context.createVertexBuffer(numCharVertices, NUM_COLOR_FLOATS_PER_VERTEX);
        var indexBuffer:IndexBuffer3D = context.createIndexBuffer(numCharIndices);

        var geomVertices:Array<Float> = [];
        var colorVertices:Array<Float> = [];
        var indices:Array<UInt> = [];

        var numCharRows:Int = 9;
        var numCharColumns:Int = 10;

        var wid:Int = TEXTURE_SIZE;
        var hgt:Int = TEXTURE_SIZE;
        var spacing:Int = 2;
        var cWid:Int = 64;
        var cHgt:Int = 64;

        var SPACE_WIDTH:Float = 2.0;
        var SPACE_HEIGHT:Float = 2.0;

        var offX:Float = (cWid + spacing) / wid;
        var offY:Float = (cHgt + spacing) / hgt;
        var fracX:Float = cWid / wid;
        var fracY:Float = cHgt / hgt;
        var sizeX:Float = SPACE_WIDTH  / Constants.NUM_COLUMNS;
        var sizeY:Float = SPACE_HEIGHT / Constants.NUM_ROWS;

        for (itr in 0...numCharQuads) {

            var charIndex:Int = itr + startCharQuad;

            var col:Int = charIndex % Constants.NUM_COLUMNS;
            var row:Int = Std.int(charIndex / Constants.NUM_COLUMNS);

            var x:Float = SPACE_WIDTH  * (col / Constants.NUM_COLUMNS - 0.5);
            var y:Float = SPACE_HEIGHT * (row / Constants.NUM_ROWS    - 0.5);
            var z:Float = -1;
            z *= Math.cos(row / Constants.NUM_ROWS    * Math.PI * 2);
            z *= Math.cos(col / Constants.NUM_COLUMNS * Math.PI * 4);
            //z = row / Constants.NUM_ROWS;
            //z = 0;

            var r:Float = Std.random(COLOR_RANGE) / (COLOR_RANGE - 1);
            var g:Float = Std.random(COLOR_RANGE) / (COLOR_RANGE - 1);
            var b:Float = Std.random(COLOR_RANGE) / (COLOR_RANGE - 1);

            r = row / Constants.NUM_ROWS;
            g = col / Constants.NUM_COLUMNS;
            b = Math.cos(r) * Math.cos(g) * 0.5;

            var u:Float = Std.random(numCharColumns) * offX;
            var v:Float = Std.random(numCharRows) * offY;

            var i:Float = Std.random(COLOR_RANGE) / (COLOR_RANGE - 1);

            /*
            r = g = b = 1;
            u = offX * 9;
            v = offY * 7;
            i = 1;
            /**/

            writeToArray(geomVertices, itr * NUM_VERTICES_PER_QUAD * NUM_GEOM_FLOATS_PER_VERTEX, [
                x        , y        ,  z,
                x        , y + sizeY,  z,
                x + sizeX, y + sizeY,  z,
                x + sizeX, y        ,  z,
            ]);

            writeToArray(colorVertices, itr * NUM_VERTICES_PER_QUAD * NUM_COLOR_FLOATS_PER_VERTEX, [
                r,  g,  b, u        , v + fracY, i,
                r,  g,  b, u        , v        , i,
                r,  g,  b, u + fracX, v        , i,
                r,  g,  b, u + fracX, v + fracY, i,
            ]);

            var firstIndex:Int = itr * NUM_VERTICES_PER_QUAD;

            writeToArray(indices, itr * NUM_INDICES_PER_QUAD, [
                firstIndex + 0, firstIndex + 1, firstIndex + 2,
                firstIndex + 0, firstIndex + 2, firstIndex + 3,
            ]);
        }

        geomBuffer.uploadFromVector(Vector.ofArray(geomVertices), 0, numCharVertices);
        colorBuffer.uploadFromVector(Vector.ofArray(colorVertices), 0, numCharVertices);
        indexBuffer.uploadFromVector(Vector.ofArray(indices), 0, numCharIndices);

        var bufferSet:BufferSet = {
            id:id,
            colors:colorBuffer,
            geom:geomBuffer,
            indices:indexBuffer,
        };

        return bufferSet;
    }

    inline function writeToArray<T>(array:Array<T>, startIndex:Int, items:Array<T>):Void {
        for (ike in 0...items.length) array[startIndex + ike] = items[ike];
    }

    function makePrettyProgram():Void {
        prettyProgram = context.createProgram();
        var assembler:AGALMiniAssembler = new AGALMiniAssembler();

        var vertCode:String = [
            "m44 vt0 va0 vc0",  // projected = mat.project(xyz)

            "mov v0 va1",        // f[0] = rgb
            "mov v1 va2",        // f[1] = uv
            "mov v2 va3",        // f[2] = i
            "mov v3 vt0.zzzz",   // f[3] = projected.z

            "max vt0.z vt0.z vc4.z",

            "mov op vt0",  // outputPosition = projected
        ].join("\n");

        var vertexShader:ByteArray = assembler.assemble("vertex", vertCode);

        var textOptions:String = "<" + [
            "2d",
            "linear",
            "miplinear", // nomip, miplinear
            "repeat",
        ].join(", ") + ">";

        var fragmentCode:String = [

            "tex ft0 v1 fs0 " + textOptions,   // char = textures[0].colorAt(f[1])

            // brightness = (i >= brightThreshold) ? i - char : i + char
            //*
            "sge ft1 fc1 v2.xxxx",    // isBright = (f[2] >= brightThreshold) ? 1 : 0     0 to 1
            "mul ft1 fc0 ft1",        // isBright *= brightMult                           0 to 2
            "mul ft1 ft0 ft1",        // isBright *= char                                 0 to 2*char
            "sub ft1 ft1 ft0",        // isBright -= brightSub                            -char to char
            "add ft1 ft1 v2.xxxx",    // brightness = f[2] + isBright
            /**/

            // brightness *= (2 - z)
            //*
            "sub ft0 fc0 v3",
            "sat ft0 ft0",
            "mul ft1 ft1 ft0",
            /**/

            //*
            "mul oc ft1 v0",          // outputColor = brightness * f[0]
            /**/

        ].join("\n");

        var fragmentShader:ByteArray = assembler.assemble("fragment", fragmentCode);

        prettyProgram.upload(vertexShader, fragmentShader); // Upload the combined prettyProgram to the video Ram
    }

    function makeMouseProgram():Void {
        mouseProgram = context.createProgram();
        var assembler:AGALMiniAssembler = new AGALMiniAssembler();

        var vertCode:String = [
            "m44 op va0 vc0",
        ].join("\n");

        var vertexShader:ByteArray = assembler.assemble("vertex", vertCode);

        var fragmentCode:String = [
            "mov oc fc2",
        ].join("\n");

        var fragmentShader:ByteArray = assembler.assemble("fragment", fragmentCode);

        mouseProgram.upload(vertexShader, fragmentShader); // Upload the combined prettyProgram to the video Ram
    }

    function makeConstants():Void {
        cameraMat  = new Matrix3D();
        projection = new PerspectiveMatrix3D();

        projection.perspectiveLH(2, 2, 1, 2);
        //projection.orthoLH(2, 2, 1, 2);
        projections = [];

        var mat:PerspectiveMatrix3D = new PerspectiveMatrix3D();
        for (ike in 0...10) {
            var centerX:Float = (ike / 11 + 1 / 11) * 2 - 1;
            var centerY:Float = (ike / 11 + 1 / 11) * 2 - 1;

            //centerX = 0;
            //centerY = 0;

            mat.identity();
            mat.perspectiveOffCenterLH(centerX - 1, centerX + 1, centerY - 1, centerY + 1, 1, 2);
            mat.appendTranslation(centerX, centerY, 0);

            projections.push(mat.clone());
        }

        var n:Float;

        n = 0.0;
        context.setProgramConstantsFromVector(Context3DProgramType.VERTEX,   4, Vector.ofArray([n,n,n,n]), 1); // vc4 contains 0.0

        n = 2.0;
        context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, Vector.ofArray([n,n,n,n]), 1); // fc0 contains 2.0
        n = 0.3;
        context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 1, Vector.ofArray([n,n,n,n]), 1); // fc1 contains 0.3
    }

    function makeTexture():Void {
        texture = context.createTexture(TEXTURE_SIZE, TEXTURE_SIZE, Context3DTextureFormat.BGRA, false);

        // MIPMAP GENERATION
        var src:BitmapData = Assets.getBitmapData("assets/profont_flat.png");

        var width:Int = 1;
        while (width < src.width) {
            width = width * 2;
        }

        var bmd:BitmapData = new BitmapData(width, width, src.transparent, 0x0);
        bmd.copyPixels(src, src.rect, bmd.rect.topLeft);

        var miplevel:Int = 0;
        while (width > 0) {
            texture.uploadFromBitmapData(getResizedBitmapData(bmd, width, false), miplevel);
            miplevel++;
            width = Std.int(width / 2);
        }
    }

    function getResizedBitmapData(bmp:BitmapData, width:UInt, smoothing:Bool):BitmapData {
        var bmpData:BitmapData = new BitmapData(width, width, bmp.transparent, 0x00FFFFFF);
        var mat:Matrix = new Matrix();
        mat.scale(width / bmp.width, width / bmp.width);
        bmpData.draw(bmp, mat, null, null, null, smoothing);
        return bmpData;
    }

    function update(?event:Event):Void {
        //var numX:Float = (stage.mouseX / stage.stageWidth) * 2 - 1;
        //var numY:Float = (stage.mouseY / stage.stageHeight) * 2 - 1;
        var numT:Float = (Timer.stamp() % 10) / 10;

        //*

        var cX:Float = 0.5 * Math.cos(numT * Math.PI * 2);
        var cY:Float = 0.5 * Math.sin(numT * Math.PI * 2);

        cameraMat.identity();
        cameraMat.appendTranslation(0, 0, 1);
        cameraMat.appendTranslation(cX, cY, 0);
        cameraMat.append(projection);

        //var vec:Vector3D = new Vector3D();
        //cameraMat.copyColumnTo(2, vec);
        //vec.x += numX;
        //vec.y += -numY;
        //cameraMat.copyColumnFrom(2, vec);
    }

    function renderPretty(?event:Event):Void {

        context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, cameraMat, true); // vc0 contains the camera matrix

        if (mode != PRETTY) {
            mode = PRETTY;
            context.setTextureAt(0, texture); // fs0 contains our texture
            context.setProgram(prettyProgram);
            context.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ONE);
        }

        context.clear(0, 0, 0, 1);

        for (bufferSet in bufferSets) {
            context.setVertexBufferAt(0, bufferSet.geom,  0, Context3DVertexBufferFormat.FLOAT_3); // va0 contains x,y,z
            context.setVertexBufferAt(1, bufferSet.colors, 0, Context3DVertexBufferFormat.FLOAT_3); // va1 contains r,g,b
            context.setVertexBufferAt(2, bufferSet.colors, 3, Context3DVertexBufferFormat.FLOAT_2); // va2 contains u,v
            context.setVertexBufferAt(3, bufferSet.colors, 5, Context3DVertexBufferFormat.FLOAT_1); // va3 contains i

            context.drawTriangles(bufferSet.indices);
        }

        context.present();
    }

    function renderMouse(?event:Event):Void {

        context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, cameraMat, true); // vc0 contains the camera matrix

        if (mode != MOUSE) {
            mode = MOUSE;
            context.setTextureAt(0, null); // fs0 is empty
            context.setProgram(mouseProgram);
            context.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO);
        }

        context.clear(0, 0, 0, 1);

        var idVec:Vector<Float> = Vector.ofArray([0., 0., 0., 0.]);

        for (bufferSet in bufferSets) {

            idVec[2] = (bufferSet.id + 1) / bufferSets.length;

            context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 2, idVec, 1); // fc2 contains ID

            context.setVertexBufferAt(0, bufferSet.geom,  0, Context3DVertexBufferFormat.FLOAT_3); // va0 contains x,y,z
            context.setVertexBufferAt(1, null, 0, Context3DVertexBufferFormat.FLOAT_3); // va1 contains r,g,b
            context.setVertexBufferAt(2, null, 3, Context3DVertexBufferFormat.FLOAT_2); // va2 contains u,v
            context.setVertexBufferAt(3, null, 5, Context3DVertexBufferFormat.FLOAT_1); // va3 contains i
            context.drawTriangles(bufferSet.indices);
        }

        context.drawToBitmapData(mouseBD);
    }

    function checkMouse(?event:Event):Void {
        mouseShape.x = stage.mouseX * mouseBitmap.scaleX;
        mouseShape.y = stage.mouseY * mouseBitmap.scaleY;

        mouseShape.alpha = (mouseBD.getPixel(Std.int(stage.mouseX), Std.int(stage.mouseY)) > 0) ? 1 : 0.5;
    }
}