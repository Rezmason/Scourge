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
import net.rezmason.scourge.textview.RenderMode;

using Lambda;

class TextDemo {

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

    var mode:RenderMode;

    var mouseBD:BitmapData;
    var mouseBitmap:Bitmap;
    var mouseShape:Shape;

    var projection:PerspectiveMatrix3D;
    var cameraMat:Matrix3D;
    var glyphMat:Matrix3D;
    var context:Context3D;
    var prettyProgram:Program3D;
    var mouseProgram:Program3D;
    var models:Array<Model>;
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
        showHideTimer.run = hideSomeGlyphs;
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
        makeModels();
        makePrettyProgram();
        makeMouseProgram();

        stage.addEventListener(Event.RESIZE, onResize);
        stage.addEventListener(Event.ACTIVATE, onActivate);
        stage.addEventListener(Event.DEACTIVATE, onDeactivate);
        stage.addEventListener(MouseEvent.CLICK, renderMouse);
        stage.addEventListener(MouseEvent.MOUSE_MOVE, checkMouse);

        onActivate();
    }

    function makeModels():Void {

        models = [];

        var modelMat:Matrix3D = new Matrix3D();

        var glyphs:Array<Glyph> = makeGlyphs();

        models.push({
            segments:makeSegments(glyphs),
            id:0,
            matrix:modelMat,
            numGlyphs:glyphs.length,
            numVisibleGlyphs:glyphs.length,
            glyphs:glyphs,
        });
    }

    function makeGlyphs():Array<Glyph> {
        var glyphs:Array<Glyph> = [];

        // TEMPORARY!!!
        var numGlyphRows:Int = 9;
        var numGlyphColumns:Int = 10;
        var wid:Int = TEXTURE_SIZE;
        var hgt:Int = TEXTURE_SIZE;
        var spacing:Int = 2;
        var cWid:Int = 64;
        var cHgt:Int = 64;
        var offX:Float = (cWid + spacing) / wid;
        var offY:Float = (cHgt + spacing) / hgt;
        var fracX:Float = cWid / wid;
        var fracY:Float = cHgt / hgt;

        for (ike in 0...Constants.NUM_CHARS) {

            var col:Int = ike % Constants.NUM_COLUMNS;
            var row:Int = Std.int(ike / Constants.NUM_COLUMNS);

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

            var u:Float = Std.random(numGlyphColumns) * offX;
            var v:Float = Std.random(numGlyphRows) * offY;

            var i:Float = Std.random(COLOR_RANGE) / (COLOR_RANGE - 1);
            var s:Float = Std.random(COLOR_RANGE) / (COLOR_RANGE - 1);

            s = 1;
            i = 0.2;
            /*
            u = offX * itr;
            v = offY * 2;
            */

            var geom:Array<Float> = [
                x, y, z, 0, 0, s,
                x, y, z, 0, 1, s,
                x, y, z, 1, 1, s,
                x, y, z, 1, 0, s,
            ];

            var color:Array<Float> = [
                r, g, b, u        , v + fracY, i,
                r, g, b, u        , v        , i,
                r, g, b, u + fracX, v        , i,
                r, g, b, u + fracX, v + fracY, i,
            ];

            glyphs.push({
                renderIndex:-1,
                renderSegmentIndex:-1,
                charCode:-1,
                color:color,
                geom:geom,
                hidden:false,
                id:ike,
            });
        }
        return glyphs;
    }

    function makeSegments(glyphs:Array<Glyph>):Array<BufferSegment> {

        var segments:Array<BufferSegment> = [];

        var remainingGlyphs:Int = Constants.NUM_CHARS;
        var startGlyph:Int = 0;

        var segmentId:Int = 0;
        while (startGlyph < Constants.NUM_CHARS) {
            var len:Int = Std.int(Math.min(remainingGlyphs, CHAR_QUAD_CHUNK));
            segments.push(makeSegment(segmentId, glyphs, startGlyph, len));

            startGlyph += CHAR_QUAD_CHUNK;
            remainingGlyphs -= CHAR_QUAD_CHUNK;
            segmentId++;
        }

        return segments;
    }

    function makeSegment(segmentId:Int, glyphs:Array<Glyph>, startGlyph:Int, numGlyphs:Int):BufferSegment {

        var numGlyphVertices:Int = numGlyphs * NUM_VERTICES_PER_QUAD;
        var numGlyphIndices:Int = numGlyphs * NUM_INDICES_PER_QUAD;

        var geomBuffer:VertexBuffer3D = context.createVertexBuffer(numGlyphVertices, NUM_GEOM_FLOATS_PER_VERTEX);
        var colorBuffer:VertexBuffer3D = context.createVertexBuffer(numGlyphVertices, NUM_COLOR_FLOATS_PER_VERTEX);
        var idBuffer:VertexBuffer3D = context.createVertexBuffer(numGlyphVertices, NUM_ID_FLOATS_PER_VERTEX);
        var indexBuffer:IndexBuffer3D = context.createIndexBuffer(numGlyphIndices);

        var geomVertices:Vector<Float> = new Vector<Float>();
        var colorVertices:Vector<Float> = new Vector<Float>();
        var idVertices:Vector<Float> = new Vector<Float>();
        var indices:Vector<UInt> = new Vector<UInt>();

        var ids:Vector<Int> = new Vector<Int>(); // TEMP

        for (itr in 0...numGlyphs) {

            var glyphIndex:Int = itr + startGlyph;

            var glyph:Glyph = glyphs[glyphIndex];

            writeArrayToVector(geomVertices, itr * NUM_GEOM_FLOATS_PER_QUAD, glyph.geom, NUM_GEOM_FLOATS_PER_QUAD);
            writeArrayToVector(colorVertices, itr * NUM_COLOR_FLOATS_PER_QUAD, glyph.color, NUM_COLOR_FLOATS_PER_QUAD);
            writeArrayToVector(idVertices, itr * NUM_ID_FLOATS_PER_QUAD, [
                0, 0, 1,
                0, 1, 0,
                1, 1, 0,
                1, 0, 0,
            ], NUM_ID_FLOATS_PER_QUAD);

            writeArrayToVector(ids, itr, [glyph.id], 1); // TEMP

            var firstIndex:Int = itr * NUM_VERTICES_PER_QUAD;

            writeArrayToVector(indices, itr * NUM_INDICES_PER_QUAD, [
                firstIndex + 0, firstIndex + 1, firstIndex + 2,
                firstIndex + 0, firstIndex + 2, firstIndex + 3,
            ], NUM_INDICES_PER_QUAD);

            glyph.renderIndex = itr;
            glyph.renderSegmentIndex = segmentId;
        }

        var segment:BufferSegment = {
            id:segmentId,
            colorBuffer:colorBuffer,
            geomBuffer:geomBuffer,
            idBuffer:idBuffer,
            indexBuffer:indexBuffer,

            colorVertices:colorVertices,
            geomVertices:geomVertices,
            idVertices:idVertices,
            indices:indices,

            numQuads:numGlyphs,

            ids:ids, // TEMP
        };

        updateSegment(segment);

        return segment;
    }

    inline function writeArrayToVector<T>(array:Vector<T>, startIndex:Int, items:Array<T>, numItems:Int):Void {
        for (ike in 0...items.length) array[startIndex + ike] = items[ike];
    }

    inline function swapBetweenVectors<T>(src:Vector<T>, dest:Vector<T>, srcIndex:Int, destIndex:Int, numItems:Int):Void {
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

            "tex ft0 v1 fs0 <2d, linear, miplinear, repeat>",   // glyph = textures[0].colorAt(f[1])

            // brightness = (i >= brightThreshold) ? i - glyph : i + glyph
            "sge ft1 fc1 v2.xxxx",    // isBright = (f[2] >= brightThreshold) ? 1 : 0     0 to 1
            "mul ft1 fc0 ft1",        // isBright *= brightMult                           0 to 2
            "mul ft1 ft0 ft1",        // isBright *= glyph                                 0 to 2*glyph
            "sub ft1 ft1 ft0",        // isBright -= brightSub                            -glyph to glyph
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
        glyphMat = new Matrix3D();

        var sizeX:Float = SPACE_WIDTH  / Constants.NUM_COLUMNS;
        var sizeY:Float = SPACE_HEIGHT / Constants.NUM_ROWS;
        glyphMat.appendScale      ( sizeX,        sizeY,       1);
        glyphMat.appendTranslation(-sizeX * 0.5, -sizeY * 0.5, 0);

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
        modelMat.appendRotation(-numX * 360 - 180, Vector3D.Z_AXIS);
        modelMat.appendRotation(-numY * 360 - 180 + 90, Vector3D.X_AXIS);
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
        context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 5, glyphMat, true); // vc5 contains the character matrix

        if (mode != RENDER_FOR_SCREEN) {
            mode = RENDER_FOR_SCREEN;
            context.setTextureAt(0, texture); // fs0 contains our texture
            context.setProgram(prettyProgram);
            context.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ONE);
        }

        context.clear(0, 0, 0, 1);

        for (model in models) {

            var numVisibleTriangles:Int = model.numVisibleGlyphs * NUM_TRIANGLES_PER_QUAD;

            context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 9, model.matrix, true); // vc9 contains the model's matrix

            for (segment in model.segments) {

                var len:Int = segment.numQuads * NUM_TRIANGLES_PER_QUAD;
                if (len > numVisibleTriangles) len = numVisibleTriangles;

                context.setVertexBufferAt(0, segment.geomBuffer,  0, Context3DVertexBufferFormat.FLOAT_3); // va0 contains x,y,z
                context.setVertexBufferAt(1, segment.geomBuffer,  3, Context3DVertexBufferFormat.FLOAT_2); // va1 contains h,v
                context.setVertexBufferAt(2, segment.geomBuffer,  5, Context3DVertexBufferFormat.FLOAT_1); // va2 contains s
                context.setVertexBufferAt(3, segment.colorBuffer, 0, Context3DVertexBufferFormat.FLOAT_3); // va3 contains r,g,b
                context.setVertexBufferAt(4, segment.colorBuffer, 3, Context3DVertexBufferFormat.FLOAT_2); // va4 contains u,v
                context.setVertexBufferAt(5, segment.colorBuffer, 5, Context3DVertexBufferFormat.FLOAT_1); // va5 contains i
                context.setVertexBufferAt(6, null, 0, Context3DVertexBufferFormat.FLOAT_3); // va6 is empty

                context.drawTriangles(segment.indexBuffer, 0, len);

                numVisibleTriangles -= len;
                if (numVisibleTriangles == 0) break;
            }
        }

        context.present();
    }

    function renderMouse(?event:Event):Void {

        context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 1, cameraMat, true); // vc1 contains the camera matrix
        context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 5, glyphMat, true); // vc5 contains the character matrix

        if (mode != RENDER_FOR_MOUSE) {
            mode = RENDER_FOR_MOUSE;
            context.setTextureAt(0, null); // fs0 is empty
            context.setProgram(mouseProgram);
            context.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO);
        }

        context.clear(0, 0, 0, 1);

        for (model in models) {

            var numVisibleTriangles:Int = model.numVisibleGlyphs * NUM_TRIANGLES_PER_QUAD;

            context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 9, model.matrix, true); // vc9 contains the model's matrix

            for (segment in model.segments) {

                var len:Int = segment.numQuads * NUM_TRIANGLES_PER_QUAD;
                if (len > numVisibleTriangles) len = numVisibleTriangles;

                context.setVertexBufferAt(0, segment.geomBuffer,  0, Context3DVertexBufferFormat.FLOAT_3); // va0 contains x,y,z
                context.setVertexBufferAt(1, segment.geomBuffer,  3, Context3DVertexBufferFormat.FLOAT_2); // va1 contains h,v
                context.setVertexBufferAt(2, null,  5, Context3DVertexBufferFormat.FLOAT_1); // va2 is empty
                context.setVertexBufferAt(3, null, 0, Context3DVertexBufferFormat.FLOAT_3); // va3 is empty
                context.setVertexBufferAt(4, null, 3, Context3DVertexBufferFormat.FLOAT_2); // va4 is empty
                context.setVertexBufferAt(5, null, 5, Context3DVertexBufferFormat.FLOAT_1); // va5 is empty
                context.setVertexBufferAt(6, segment.idBuffer, 0, Context3DVertexBufferFormat.FLOAT_3); // va6 contains id

                context.drawTriangles(segment.indexBuffer, 0, len);

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

    function hideSomeGlyphs():Void {
        var model:Model = models[0];
        var indices:Array<Int> = [];
        indices.push(model.segments[0].ids.indexOf(model.numVisibleGlyphs - 1)); // TEMP
        toggleGlyphs(model, indices, false);
        if (model.numVisibleGlyphs <= 0) {
            showHideTimer.run = showSomeGlyphs;
        }
    }

    function showSomeGlyphs():Void {
        var model:Model = models[0];
        var indices:Array<Int> = [];
        indices.push(model.segments[0].ids.indexOf(model.numVisibleGlyphs)); // TEMP
        toggleGlyphs(model, indices, true);
        if (model.numVisibleGlyphs >= model.numGlyphs) {
            showHideTimer.run = hideSomeGlyphs;
        }
    }

    function toggleGlyphs(model:Model, indices:Array<Int>, visible:Bool):Void {

        var numVisibleGlyphs:Int = model.numVisibleGlyphs;

        var indicesToChange:Array<Int> = [];
        for (index in indices) if (index >= numVisibleGlyphs == visible) indicesToChange.push(index);

        var invalidBuffers:Array<Bool> = [];

        var step:Int = visible ? 1 : -1;
        var offset:Int = visible ? 0 : -1;

        for (index in indicesToChange) {

            var srcBufferIndex:Int = Std.int(index / CHAR_QUAD_CHUNK);
            var srcBuffer:BufferSegment = model.segments[srcBufferIndex];
            var srcIndex:Int = index % CHAR_QUAD_CHUNK;

            var destBufferIndex:Int = Std.int((numVisibleGlyphs + offset) / CHAR_QUAD_CHUNK);
            var destBuffer:BufferSegment = model.segments[destBufferIndex];
            var destIndex:Int = (numVisibleGlyphs + offset) % CHAR_QUAD_CHUNK;

            swapBetweenVectors(srcBuffer.indices, destBuffer.indices, srcIndex * NUM_INDICES_PER_QUAD,      destIndex * NUM_INDICES_PER_QUAD,      NUM_INDICES_PER_QUAD);
            swapBetweenVectors(srcBuffer.ids, destBuffer.ids, srcIndex, destIndex, 1); // TEMP

            numVisibleGlyphs += step;
            invalidBuffers[srcBufferIndex] = true;
            invalidBuffers[destBufferIndex] = true;
        }

        for (ike in 0...invalidBuffers.length) if (invalidBuffers[ike]) updateSegment(model.segments[ike]);

        model.numVisibleGlyphs = numVisibleGlyphs;
    }

    function updateSegment(segment:BufferSegment):Void {

        // EXPENSIVE! Use a flag system to indicate what's invalid in a segment

        var numGlyphVertices:Int = segment.numQuads * NUM_VERTICES_PER_QUAD;
        var numGlyphIndices:Int = segment.numQuads * NUM_INDICES_PER_QUAD;

        segment.geomBuffer.uploadFromVector(segment.geomVertices, 0, numGlyphVertices);
        segment.colorBuffer.uploadFromVector(segment.colorVertices, 0, numGlyphVertices);
        segment.idBuffer.uploadFromVector(segment.idVertices, 0, numGlyphVertices);
        segment.indexBuffer.uploadFromVector(segment.indices, 0, numGlyphIndices);
    }
}
