package net.rezmason.scourge.textview;

import com.adobe.utils.AGALMiniAssembler;
import com.adobe.utils.PerspectiveMatrix3D;
import haxe.Timer;
import nme.display.Bitmap;
import nme.display.BitmapData;
import nme.display.BitmapDataChannel;
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
import nme.filters.BitmapFilterQuality;
import nme.filters.GlowFilter;
import nme.geom.Matrix3D;
import nme.geom.Matrix;
import nme.geom.Vector3D;
import nme.utils.ByteArray;
import nme.utils.Timer;
import nme.Vector;

import net.rezmason.utils.FlatFont;

using Lambda;

enum FuckMode {
    MOUSE;
    PRETTY;
}

typedef FuckModel = {
    var bufferSets:Array<BufferSet>;
    var id:Int;
    var matrix:Matrix3D;
    var numChars:Int;
    var numVisibleChars:Int;
}

typedef BufferSet = {
    var id:Int;

    var colorBuffer:VertexBuffer3D;
    var geomBuffer:VertexBuffer3D;
    var idBuffer:VertexBuffer3D;
    var indexBuffer:IndexBuffer3D;

    var colorVertices:Vector<Float>;
    var geomVertices:Vector<Float>;
    var idVertices:Vector<Float>;
    var indices:Vector<UInt>;

    var ids:Vector<Int>; // TEMP

    var numQuads:Int;
}

class Stage3DFuckbox {

    inline static var SPACE_WIDTH:Float = 2.0;
    inline static var SPACE_HEIGHT:Float = 2.0;
    inline static var TEXTURE_SIZE:Int = 1024;

    inline static var NUM_GEOM_FLOATS_PER_VERTEX:Int = 3 + 2 + 1; // X,Y,Z H,V S
    inline static var NUM_COLOR_FLOATS_PER_VERTEX:Int = 3 + 2 + 1; // R,G,B U,V I
    inline static var NUM_ID_FLOATS_PER_VERTEX:Int = 3; // ID, BUFFER_SET, GROUP

    inline static var NUM_VERTICES_PER_QUAD:Int = 4;
    inline static var NUM_GEOM_FLOATS_PER_QUAD:Int = NUM_GEOM_FLOATS_PER_VERTEX * NUM_VERTICES_PER_QUAD;
    inline static var NUM_COLOR_FLOATS_PER_QUAD:Int = NUM_COLOR_FLOATS_PER_VERTEX * NUM_VERTICES_PER_QUAD;
    inline static var NUM_ID_FLOATS_PER_QUAD:Int = NUM_ID_FLOATS_PER_VERTEX * NUM_VERTICES_PER_QUAD;

    inline static var NUM_TRIANGLES_PER_QUAD:Int = 2;
    inline static var NUM_INDICES_PER_TRIANGLE:Int = 3;
    inline static var NUM_INDICES_PER_QUAD:Int = NUM_TRIANGLES_PER_QUAD * NUM_INDICES_PER_TRIANGLE;
    inline static var COLOR_RANGE:Int = 6;
    inline static var BUFFER_SIZE:Int = 0xFFFF;
    inline static var CHAR_QUAD_CHUNK:Int = Std.int(BUFFER_SIZE / NUM_VERTICES_PER_QUAD);

    var stage:Stage;
    var stage3D:Stage3D;

    var mode:FuckMode;

    var mouseBD:BitmapData;
    var mouseBitmap:Bitmap;
    var mouseShape:Shape;

    var projection:PerspectiveMatrix3D;
    var cameraMat:Matrix3D;
    var charMat:Matrix3D;
    var context:Context3D;
    var prettyProgram:Program3D;
    var mouseProgram:Program3D;
    var models:Array<FuckModel>;
    var texture:Texture;
    var showHideTimer:Timer;
    var font:FlatFont;

    public function new(stage:Stage, font:FlatFont) {
        this.stage = stage;
        this.font = font;

        mouseBitmap = new Bitmap();
        mouseBitmap.scaleX = mouseBitmap.scaleY = 0.15;
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

        showHideTimer = new Timer(1);
        showHideTimer.run = hideSomeChars;
    }

    function configureBuffer():Void {
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
        makeFuckModels();
        makePrettyProgram();
        makeMouseProgram();

        stage.addEventListener(Event.RESIZE, onResize);
        stage.addEventListener(Event.ACTIVATE, onActivate);
        stage.addEventListener(Event.DEACTIVATE, onDeactivate);
        stage.addEventListener(MouseEvent.CLICK, renderMouse);
        stage.addEventListener(MouseEvent.MOUSE_MOVE, checkMouse);

        onActivate();
    }

    function makeFuckModels():Void {

        models = [];

        var modelMat:Matrix3D = new Matrix3D();

        models.push({
            bufferSets:makeBufferSets(0),
            id:0,
            matrix:modelMat,
            numChars:Constants.NUM_CHARS,
            numVisibleChars:Constants.NUM_CHARS,
        });
    }

    function makeBufferSets(groupId:Int):Array<BufferSet> {

        var bufferSets:Array<BufferSet> = [];

        var remainingCharQuads:Int = Constants.NUM_CHARS;
        var startCharQuad:Int = 0;

        var bufferId:Int = 0;
        while (startCharQuad < Constants.NUM_CHARS) {
            var len:Int = Std.int(Math.min(remainingCharQuads, CHAR_QUAD_CHUNK));
            bufferSets.push(makeBufferSet(bufferId, groupId, startCharQuad, len));

            startCharQuad += CHAR_QUAD_CHUNK;
            remainingCharQuads -= CHAR_QUAD_CHUNK;
            bufferId++;
        }

        return bufferSets;
    }

    function makeBufferSet(bufferId:Int, groupId:Int, startCharQuad:Int, numCharQuads:Int):BufferSet {

        var numCharVertices:Int = numCharQuads * NUM_VERTICES_PER_QUAD;
        var numCharIndices:Int = numCharQuads * NUM_INDICES_PER_QUAD;

        var geomBuffer:VertexBuffer3D = context.createVertexBuffer(numCharVertices, NUM_GEOM_FLOATS_PER_VERTEX);
        var colorBuffer:VertexBuffer3D = context.createVertexBuffer(numCharVertices, NUM_COLOR_FLOATS_PER_VERTEX);
        var idBuffer:VertexBuffer3D = context.createVertexBuffer(numCharVertices, NUM_ID_FLOATS_PER_VERTEX);
        var indexBuffer:IndexBuffer3D = context.createIndexBuffer(numCharIndices);

        var geomVertices:Vector<Float> = new Vector<Float>();
        var colorVertices:Vector<Float> = new Vector<Float>();
        var idVertices:Vector<Float> = new Vector<Float>();
        var indices:Vector<UInt> = new Vector<UInt>();

        var ids:Vector<Int> = new Vector<Int>(); // TEMP

        var numCharRows:Int = 9;
        var numCharColumns:Int = 10;

        var wid:Int = TEXTURE_SIZE;
        var hgt:Int = TEXTURE_SIZE;
        var spacing:Int = 2;
        var cWid:Int = 64;
        var cHgt:Int = 64;

        var offX:Float = (cWid + spacing) / wid;
        var offY:Float = (cHgt + spacing) / hgt;
        var fracX:Float = cWid / wid;
        var fracY:Float = cHgt / hgt;

        for (itr in 0...numCharQuads) {

            var charIndex:Int = itr + startCharQuad;

            var col:Int = charIndex % Constants.NUM_COLUMNS;
            var row:Int = Std.int(charIndex / Constants.NUM_COLUMNS);

            var x:Float = ((col + 0.5) / Constants.NUM_COLUMNS - 0.5);
            var y:Float = ((row + 0.5) / Constants.NUM_ROWS    - 0.5);
            var z:Float = -1;
            z *= Math.cos(row / Constants.NUM_ROWS    * Math.PI * 2);
            z *= Math.cos(col / Constants.NUM_COLUMNS * Math.PI * 2);
            //z = 0;

            var r:Float = Std.random(COLOR_RANGE) / (COLOR_RANGE - 1);
            var g:Float = Std.random(COLOR_RANGE) / (COLOR_RANGE - 1);
            var b:Float = Std.random(COLOR_RANGE) / (COLOR_RANGE - 1);

            //*
            r = row / Constants.NUM_ROWS;
            g = col / Constants.NUM_COLUMNS;
            b = Math.cos(r) * Math.cos(g) * 0.5;
            /**/

            //r = g = b = 1;

            var u:Float = Std.random(numCharColumns) * offX;
            var v:Float = Std.random(numCharRows) * offY;

            var i:Float = Std.random(COLOR_RANGE) / (COLOR_RANGE - 1);
            var s:Float = Std.random(COLOR_RANGE) / (COLOR_RANGE - 1);

            s = 1;
            i = 0.2;
            /*
            u = offX * itr;
            v = offY * 2;
            */

            writeArrayToVector(geomVertices, itr * NUM_GEOM_FLOATS_PER_QUAD, [
                x, y, z, 0, 0, s,
                x, y, z, 0, 1, s,
                x, y, z, 1, 1, s,
                x, y, z, 1, 0, s,
            ], NUM_GEOM_FLOATS_PER_QUAD);

            writeArrayToVector(colorVertices, itr * NUM_COLOR_FLOATS_PER_QUAD, [
                r, g, b, u        , v + fracY, i,
                r, g, b, u        , v        , i,
                r, g, b, u + fracX, v        , i,
                r, g, b, u + fracX, v + fracY, i,
            ], NUM_COLOR_FLOATS_PER_QUAD);

            writeArrayToVector(idVertices, itr * NUM_ID_FLOATS_PER_QUAD, [
                0, 0, 1,
                0, 1, 0,
                1, 1, 0,
                1, 0, 0,
            ], NUM_ID_FLOATS_PER_QUAD);

            writeArrayToVector(ids, itr, [charIndex], 1); // TEMP

            var firstIndex:Int = itr * NUM_VERTICES_PER_QUAD;

            writeArrayToVector(indices, itr * NUM_INDICES_PER_QUAD, [
                firstIndex + 0, firstIndex + 1, firstIndex + 2,
                firstIndex + 0, firstIndex + 2, firstIndex + 3,
            ], NUM_INDICES_PER_QUAD);
        }

        var bufferSet:BufferSet = {
            id:bufferId,
            colorBuffer:colorBuffer,
            geomBuffer:geomBuffer,
            idBuffer:idBuffer,
            indexBuffer:indexBuffer,

            colorVertices:colorVertices,
            geomVertices:geomVertices,
            idVertices:idVertices,
            indices:indices,

            numQuads:numCharQuads,

            ids:ids, // TEMP
        };

        updateBufferSet(bufferSet);

        return bufferSet;
    }

    inline function writeArrayToVector<T>(array:Vector<T>, startIndex:Int, items:Array<T>, numItems:Int):Void {
        for (ike in 0...items.length) array[startIndex + ike] = items[ike];
    }

    inline function swapBetweenArrays<T>(src:Vector<T>, dest:Vector<T>, srcIndex:Int, destIndex:Int, numItems:Int):Void {
        for (ike in 0...numItems) {
            var srcVal:T = src[srcIndex + ike];
            src[srcIndex + ike] = dest[destIndex + ike];
            dest[destIndex + ike] = srcVal;
        }
    }

    function makePrettyProgram():Void {
        prettyProgram = context.createProgram();
        var assembler:AGALMiniAssembler = new AGALMiniAssembler();

        var vertCode:String = [
            "m44 vt1 va1 vc5",  // corner = quadMat.project(hv) * s
            "mul vt1.xy vt1.xy va2.xx",
            "m44 vt0 va0 vc9",  // projected = mat.project(xyz)
            "m44 vt0 vt0 vc1",  // projected = mat.project(xyz)
            "add vt0.xy vt0.xy vt1.xy",  // pos = corner.xy + projected

            "mov v0 va3",        // f[0] = rgb
            "mov v1 va4",        // f[1] = uv
            "mov v2 va5",        // f[2] = i
            "mov v3 vt0.zzzz",   // f[3] = pos.z

            "max vt0.z vt0.z vc0.z", // flatten the z that go beyond the frustum

            "mov op vt0",  // outputPosition = pos
        ].join("\n");

        var vertexShader:ByteArray = assembler.assemble("vertex", vertCode);

        var fragmentCode:String = [

            "tex ft0 v1 fs0 <2d, linear, miplinear, repeat>",   // char = textures[0].colorAt(f[1])

            // brightness = (i >= brightThreshold) ? i - char : i + char
            "sge ft1 fc1 v2.xxxx",    // isBright = (f[2] >= brightThreshold) ? 1 : 0     0 to 1
            "mul ft1 fc0 ft1",        // isBright *= brightMult                           0 to 2
            "mul ft1 ft0 ft1",        // isBright *= char                                 0 to 2*char
            "sub ft1 ft1 ft0",        // isBright -= brightSub                            -char to char
            "add ft1 ft1 v2.xxxx",    // brightness = f[2] + isBright

            // brightness *= (2 - z)
            "sub ft0 fc0 v3",
            "sat ft0 ft0",
            "mul ft1 ft1 ft0",

            "mul oc ft1 v0",          // outputColor = brightness * f[0]

        ].join("\n");

        var fragmentShader:ByteArray = assembler.assemble("fragment", fragmentCode);

        prettyProgram.upload(vertexShader, fragmentShader); // Upload the combined prettyProgram to the video Ram
    }

    function makeMouseProgram():Void {
        mouseProgram = context.createProgram();
        var assembler:AGALMiniAssembler = new AGALMiniAssembler();

        var vertCode:String = [
            "m44 vt1 va1 vc5",  // corner = quadMat.project(hv)

            "m44 vt0 va0 vc9",  // projected = mat.project(xyz)
            "m44 vt0 vt0 vc1",  // projected = mat.project(xyz)
            "add vt0.xy vt0.xy vt1.xy",  // pos = corner.xy + projected

            "mov v0 va6", // f[0] = id

            "mov op vt0",  // outputPosition = pos
        ].join("\n");

        var vertexShader:ByteArray = assembler.assemble("vertex", vertCode);

        var fragmentCode:String = [
            "mov oc v0",
        ].join("\n");

        var fragmentShader:ByteArray = assembler.assemble("fragment", fragmentCode);

        mouseProgram.upload(vertexShader, fragmentShader); // Upload the combined prettyProgram to the video Ram
    }

    function makeConstants():Void {
        cameraMat = new Matrix3D();
        charMat = new Matrix3D();

        var sizeX:Float = SPACE_WIDTH  / Constants.NUM_COLUMNS;
        var sizeY:Float = SPACE_HEIGHT / Constants.NUM_ROWS;
        charMat.appendScale      ( sizeX,        sizeY,       1);
        charMat.appendTranslation(-sizeX * 0.5, -sizeY * 0.5, 0);

        projection = new PerspectiveMatrix3D();

        projection.perspectiveLH(2, 2, 1, 2);
        //projection.orthoLH(2, 2, 1, 2);

        var n:Float;

        n = 0.0;
        context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 0, Vector.ofArray([n,n,n,n]), 1); // vc0 contains 0.0

        n = 2.0;
        context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, Vector.ofArray([n,n,n,n]), 1); // fc0 contains 2.0
        n = 0.3;
        context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 1, Vector.ofArray([n,n,n,n]), 1); // fc1 contains 0.3
    }

    function makeTexture():Void {
        texture = context.createTexture(TEXTURE_SIZE, TEXTURE_SIZE, Context3DTextureFormat.BGRA, false);

        // MIPMAP GENERATION
        var src:BitmapData = font.getBitmapDataClone();

        var width:Int = 1;
        while (width < src.width) {
            width = width * 2;
        }

        var bmd:BitmapData = new BitmapData(width, width, true, 0x0);
        //bmd.copyPixels(src, src.rect, bmd.rect.topLeft);
        bmd.fillRect(bmd.rect, 0xFFFFFFFF);
        bmd.copyChannel(src, src.rect, bmd.rect.topLeft, BitmapDataChannel.RED, BitmapDataChannel.ALPHA);
        bmd.applyFilter(bmd, bmd.rect, bmd.rect.topLeft,
            new GlowFilter(
                0xFF000000,
                1.0,
                5,
                5,
                1,
                BitmapFilterQuality.HIGH,
                true
            )
        );
        //stage.addChild(new Bitmap(bmd));

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

        var modelMat:Matrix3D = models[0].matrix;
        modelMat.identity();

        //*

        var numX:Float = (stage.mouseX / stage.stageWidth) * 2 - 1;
        var numY:Float = (stage.mouseY / stage.stageHeight) * 2 - 1;
        var numT:Float = (Timer.stamp() % 10) / 10;

        var cX:Float = 0.5 * Math.cos(numT * Math.PI * 2);
        var cY:Float = 0.5 * Math.sin(numT * Math.PI * 2);
        var cZ:Float = 0.1 * Math.sin(numT * Math.PI * 2 * 5);
        /**/

        //*
        modelMat.appendRotation(numX * 360 - 180, Vector3D.Z_AXIS);
        modelMat.appendRotation(numY * 360 - 180 + 90, Vector3D.X_AXIS);
        //modelMat.appendTranslation(0, 0, cZ);

        modelMat.appendTranslation(0, 0, 0.5);

        /**/

        cameraMat.identity();
        cameraMat.appendScale(SPACE_WIDTH, SPACE_HEIGHT, 1); // Where does this belong?
        cameraMat.appendTranslation(0, 0, 1);
        //cameraMat.appendRotation(numX * 360 - 180, Vector3D.Z_AXIS);
        cameraMat.append(projection);

        //var vec:Vector3D = new Vector3D();
        //cameraMat.copyColumnTo(2, vec);
        //vec.x += numX;
        //vec.y += -numY;
        //cameraMat.copyColumnFrom(2, vec);
    }

    function renderPretty(?event:Event):Void {

        context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 1, cameraMat, true); // vc1 contains the camera matrix
        context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 5, charMat, true); // vc5 contains the character matrix

        if (mode != PRETTY) {
            mode = PRETTY;
            context.setTextureAt(0, texture); // fs0 contains our texture
            context.setProgram(prettyProgram);
            context.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ONE);
        }

        context.clear(0, 0, 0, 1);

        for (model in models) {

            var numVisibleTriangles:Int = model.numVisibleChars * NUM_TRIANGLES_PER_QUAD;

            context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 9, model.matrix, true); // vc9 contains the model's matrix

            for (bufferSet in model.bufferSets) {

                var len:Int = bufferSet.numQuads * NUM_TRIANGLES_PER_QUAD;
                if (len > numVisibleTriangles) len = numVisibleTriangles;

                context.setVertexBufferAt(0, bufferSet.geomBuffer,  0, Context3DVertexBufferFormat.FLOAT_3); // va0 contains x,y,z
                context.setVertexBufferAt(1, bufferSet.geomBuffer,  3, Context3DVertexBufferFormat.FLOAT_2); // va1 contains h,v
                context.setVertexBufferAt(2, bufferSet.geomBuffer,  5, Context3DVertexBufferFormat.FLOAT_1); // va2 contains s
                context.setVertexBufferAt(3, bufferSet.colorBuffer, 0, Context3DVertexBufferFormat.FLOAT_3); // va3 contains r,g,b
                context.setVertexBufferAt(4, bufferSet.colorBuffer, 3, Context3DVertexBufferFormat.FLOAT_2); // va4 contains u,v
                context.setVertexBufferAt(5, bufferSet.colorBuffer, 5, Context3DVertexBufferFormat.FLOAT_1); // va5 contains i
                context.setVertexBufferAt(6, null, 0, Context3DVertexBufferFormat.FLOAT_3); // va6 is empty

                context.drawTriangles(bufferSet.indexBuffer, 0, len);

                numVisibleTriangles -= len;
                if (numVisibleTriangles == 0) break;
            }
        }

        context.present();
    }

    function renderMouse(?event:Event):Void {

        context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 1, cameraMat, true); // vc1 contains the camera matrix
        context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 5, charMat, true); // vc5 contains the character matrix

        if (mode != MOUSE) {
            mode = MOUSE;
            context.setTextureAt(0, null); // fs0 is empty
            context.setProgram(mouseProgram);
            context.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO);
        }

        context.clear(0, 0, 0, 1);

        for (model in models) {

            var numVisibleTriangles:Int = model.numVisibleChars * NUM_TRIANGLES_PER_QUAD;

            context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 9, model.matrix, true); // vc9 contains the model's matrix

            for (bufferSet in model.bufferSets) {

                var len:Int = bufferSet.numQuads * NUM_TRIANGLES_PER_QUAD;
                if (len > numVisibleTriangles) len = numVisibleTriangles;

                context.setVertexBufferAt(0, bufferSet.geomBuffer,  0, Context3DVertexBufferFormat.FLOAT_3); // va0 contains x,y,z
                context.setVertexBufferAt(1, bufferSet.geomBuffer,  3, Context3DVertexBufferFormat.FLOAT_2); // va1 contains h,v
                context.setVertexBufferAt(2, null,  5, Context3DVertexBufferFormat.FLOAT_1); // va2 is empty
                context.setVertexBufferAt(3, null, 0, Context3DVertexBufferFormat.FLOAT_3); // va3 is empty
                context.setVertexBufferAt(4, null, 3, Context3DVertexBufferFormat.FLOAT_2); // va4 is empty
                context.setVertexBufferAt(5, null, 5, Context3DVertexBufferFormat.FLOAT_1); // va5 is empty
                context.setVertexBufferAt(6, bufferSet.idBuffer, 0, Context3DVertexBufferFormat.FLOAT_3); // va6 contains id

                context.drawTriangles(bufferSet.indexBuffer, 0, len);

                numVisibleTriangles -= len;
                if (numVisibleTriangles == 0) break;
            }
        }

        context.drawToBitmapData(mouseBD);
    }

    function checkMouse(?event:Event):Void {
        mouseShape.x = stage.mouseX * mouseBitmap.scaleX;
        mouseShape.y = stage.mouseY * mouseBitmap.scaleY;

        mouseShape.alpha = (mouseBD.getPixel(Std.int(stage.mouseX), Std.int(stage.mouseY)) > 0) ? 1 : 0.5;
    }

    function onResize(?event:Event):Void {
        configureBuffer();
        // defer a render
    }

    function onActivate(?event:Event):Void {
        stage.addEventListener(Event.ENTER_FRAME, onEnterFrame);
    }

    function onDeactivate(?event:Event):Void {
        stage.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
    }

    function onEnterFrame(?event:Event):Void {
        update();
        renderPretty();
    }

    function hideSomeChars():Void {
        var model:FuckModel = models[0];
        var indices:Array<Int> = [];
        indices.push(model.bufferSets[0].ids.indexOf(model.numVisibleChars - 1)); // TEMP
        toggleChars(model, indices, false);
        if (model.numVisibleChars <= 0) {
            showHideTimer.run = showSomeChars;
        }
    }

    function showSomeChars():Void {
        var model:FuckModel = models[0];
        var indices:Array<Int> = [];
        indices.push(model.bufferSets[0].ids.indexOf(model.numVisibleChars)); // TEMP
        toggleChars(model, indices, true);
        if (model.numVisibleChars >= model.numChars) {
            showHideTimer.run = hideSomeChars;
        }
    }

    function toggleChars(model:FuckModel, indices:Array<Int>, visible:Bool):Void {

        var numVisibleChars:Int = model.numVisibleChars;

        var indicesToChange:Array<Int> = [];
        for (index in indices) if (index >= numVisibleChars == visible) indicesToChange.push(index);

        var invalidBuffers:Array<Bool> = [];

        var step:Int = visible ? 1 : -1;
        var offset:Int = visible ? 0 : -1;

        for (index in indicesToChange) {

            var srcBufferIndex:Int = Std.int(index / CHAR_QUAD_CHUNK);
            var srcBuffer:BufferSet = model.bufferSets[srcBufferIndex];
            var srcIndex:Int = index % CHAR_QUAD_CHUNK;

            var destBufferIndex:Int = Std.int((numVisibleChars + offset) / CHAR_QUAD_CHUNK);
            var destBuffer:BufferSet = model.bufferSets[destBufferIndex];
            var destIndex:Int = (numVisibleChars + offset) % CHAR_QUAD_CHUNK;

            swapBetweenArrays(srcBuffer.indices, destBuffer.indices, srcIndex * NUM_INDICES_PER_QUAD,      destIndex * NUM_INDICES_PER_QUAD,      NUM_INDICES_PER_QUAD);
            swapBetweenArrays(srcBuffer.ids, destBuffer.ids, srcIndex, destIndex, 1); // TEMP

            numVisibleChars += step;
            invalidBuffers[srcBufferIndex] = true;
            invalidBuffers[destBufferIndex] = true;
        }

        for (ike in 0...invalidBuffers.length) if (invalidBuffers[ike]) updateBufferSet(model.bufferSets[ike]);

        model.numVisibleChars = numVisibleChars;
    }

    function updateBufferSet(bufferSet:BufferSet):Void {

        var numCharVertices:Int = bufferSet.numQuads * NUM_VERTICES_PER_QUAD;
        var numCharIndices:Int = bufferSet.numQuads * NUM_INDICES_PER_QUAD;

        bufferSet.geomBuffer.uploadFromVector(bufferSet.geomVertices, 0, numCharVertices);
        bufferSet.colorBuffer.uploadFromVector(bufferSet.colorVertices, 0, numCharVertices);
        bufferSet.idBuffer.uploadFromVector(bufferSet.idVertices, 0, numCharVertices);
        bufferSet.indexBuffer.uploadFromVector(bufferSet.indices, 0, numCharIndices);
    }
}
