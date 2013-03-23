package net.rezmason.scourge.textview;

import com.adobe.utils.AGALMiniAssembler;
import com.adobe.utils.PerspectiveMatrix3D;
import haxe.Timer;
import nme.display.Bitmap;
import nme.display.BitmapData;
import nme.display.Shape;
import nme.display.Stage3D;
import nme.display.Stage;
import nme.display3D.Context3D;
import nme.display3D.Context3DBlendFactor;
import nme.display3D.Context3DCompareMode;
import nme.display3D.Context3DProgramType;
import nme.display3D.Context3DVertexBufferFormat;
import nme.display3D.Program3D;
import nme.events.Event;
import nme.events.MouseEvent;
import nme.geom.Matrix3D;
import nme.geom.Rectangle;
import nme.geom.Vector3D;
import nme.utils.ByteArray;
import nme.Vector;

import net.rezmason.utils.FlatFont;
import net.rezmason.scourge.textview.RenderMode;

using Lambda;
using net.rezmason.scourge.textview.GlyphUtils;

class TextDemo {

    inline static var SPACE_WIDTH:Float = 2.0;
    inline static var SPACE_HEIGHT:Float = 2.0;

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
    var showHideFunc:Void->Void;
    var font:FlatFont;

    public function new(stage:Stage, font:FlatFont) {
        this.stage = stage;
        this.font = font;

        mouseBitmap = new Bitmap();
        mouseBitmap.scaleX = mouseBitmap.scaleY = 0.2;
        mouseShape = new Shape();
        mouseShape.graphics.beginFill(0xFFFFFF);
        mouseShape.graphics.lineTo(0, 20);
        mouseShape.graphics.lineTo(10, 16);
        mouseShape.graphics.endFill();
        /*
        stage.addChild(mouseBitmap);
        stage.addChild(mouseShape);
        */

        stage3D = stage.stage3Ds[0];
        stage3D.addEventListener(Event.CONTEXT3D_CREATE, onCreate);
        stage3D.requestContext3D();

        showHideFunc = hideSomeGlyphs;
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

        var modelMat:Matrix3D = new Matrix3D();
        var modelScissorRect:Rectangle = new Rectangle(0, 0, stage.stageWidth, stage.stageHeight);
        var model:Model = null;
        //model = new AlphabetModel(0, context, font);
        model = new TestModel(0, context, font); // TEMPORARY
        //model = new FlatModel(0, context, font); // TEMPORARY
        model.matrix = modelMat;
        model.scissorRectangle = modelScissorRect;
        models = [model];

        makeConstants();
        makePrettyProgram();
        makeMouseProgram();

        stage.addEventListener(Event.RESIZE, onResize);
        stage.addEventListener(Event.ACTIVATE, onActivate);
        stage.addEventListener(Event.DEACTIVATE, onDeactivate);
        stage.addEventListener(MouseEvent.CLICK, renderMouse);
        stage.addEventListener(MouseEvent.MOUSE_MOVE, checkMouse);

        onActivate();
    }

    function makePrettyProgram():Void {
        prettyProgram = context.createProgram();
        var assembler:AGALMiniAssembler = new AGALMiniAssembler();

        var vertCode:String = [
            "m44 vt1 va1 vc5",  // corner = glyphMat.project(hv) * s
            "mul vt1.xy vt1.xy va2.xx",
            "m44 vt0 va0 vc9",  // projected = mat.project(xyz)
            "m44 vt0 vt0 vc1",  // projected = mat.project(xyz)
            "add vt0.xy vt0.xy vt1.xy",  // pos = corner.xy + projected

            "mov v0 va3",        // fInput[0] = rgba
            "mov v1 va4",        // fInput[1] = uv
            "mov v2 va5",        // fInput[2] = i
            "mov v3 vt0.zzzz",   // fInput[3] = pos.z

            "max vt0.z vt0.z vc0.z", // flatten the z that go beyond the frustum

            "mov op vt0",  // outputPosition = pos
        ].join("\n");

        var vertexShader:ByteArray = assembler.assemble("vertex", vertCode);

        var fragmentCode:String = [

            "tex ft0 v1 fs0 <2d, linear, miplinear, repeat>",   // glyph = textures[0].colorAt(fInput[1])

            // brightness = (i >= brightThreshold) ? i - glyph : i + glyph
            "sge ft1 fc1 v2.xxxx",    // isBright = (fInput[2] >= brightThreshold) ? 1 : 0     0 to 1
            "mul ft1 fc0 ft1",        // isBright *= brightMult                           0 to 2
            "mul ft1 ft0 ft1",        // isBright *= glyph                                 0 to 2*glyph
            "sub ft1 ft1 ft0",        // isBright -= brightSub                            -glyph to glyph
            "add ft1 ft1 v2.xxxx",    // brightness = fInput[2] + isBright

            // brightness *= (2 - z)
            "sub ft0 fc0 v3",
            "sat ft0 ft0",
            "mul ft1 ft1 ft0",

            "mul oc ft1 v0",          // outputColor = brightness * fInput[0]

        ].join("\n");

        var fragmentShader:ByteArray = assembler.assemble("fragment", fragmentCode);

        prettyProgram.upload(vertexShader, fragmentShader); // Upload the combined prettyProgram to the video Ram
    }

    function makeMouseProgram():Void {
        mouseProgram = context.createProgram();
        var assembler:AGALMiniAssembler = new AGALMiniAssembler();

        var vertCode:String = [
            "m44 vt1 va1 vc5",  // corner = glyphMat.project(hv)

            "m44 vt0 va0 vc9",  // projected = mat.project(xyz)
            "m44 vt0 vt0 vc1",  // projected = mat.project(xyz)
            "add vt0.xy vt0.xy vt1.xy",  // pos = corner.xy + projected

            "mov v0 va6", // f[0] = paint

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
        modelMat.appendTranslation(0, 0, cZ);

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
            context.setProgram(prettyProgram);
            context.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ONE);
        }

        context.clear(0, 0, 0, 1);

        for (model in models) {

            if (model.numGlyphs == 0) continue;

            context.setTextureAt(0, model.texture); // fs0 contains our texture
            context.setScissorRectangle(model.scissorRectangle);

            context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 9, model.matrix, true); // vc9 contains the model's matrix

            for (ike in 0...model.numSegments) {

                var segment = model.segments[ike];
                var len:Int = segment.numVisibleGlyphs * Almanac.NUM_TRIANGLES_PER_GLYPH;

                context.setVertexBufferAt(0, segment.shapeBuffer,  0, Context3DVertexBufferFormat.FLOAT_3); // va0 contains x,y,z
                context.setVertexBufferAt(1, segment.shapeBuffer,  3, Context3DVertexBufferFormat.FLOAT_2); // va1 contains h,v
                context.setVertexBufferAt(2, segment.shapeBuffer,  5, Context3DVertexBufferFormat.FLOAT_1); // va2 contains s
                context.setVertexBufferAt(3, segment.colorBuffer, 0, Context3DVertexBufferFormat.FLOAT_3); // va3 contains r,g,b
                context.setVertexBufferAt(4, segment.colorBuffer, 3, Context3DVertexBufferFormat.FLOAT_2); // va4 contains u,v
                context.setVertexBufferAt(5, segment.colorBuffer, 5, Context3DVertexBufferFormat.FLOAT_1); // va5 contains i
                context.setVertexBufferAt(6, null, 0, Context3DVertexBufferFormat.FLOAT_3); // va6 is empty

                context.drawTriangles(segment.indexBuffer, 0, len);
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

            if (model.numGlyphs == 0) continue;

            context.setScissorRectangle(model.scissorRectangle);

            var numVisibleTriangles:Int = model.numVisibleGlyphs * Almanac.NUM_TRIANGLES_PER_GLYPH;

            context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 9, model.matrix, true); // vc9 contains the model's matrix

            for (segment in model.segments) {

                var len:Int = segment.numGlyphs * Almanac.NUM_TRIANGLES_PER_GLYPH;
                if (len > numVisibleTriangles) len = numVisibleTriangles;

                context.setVertexBufferAt(0, segment.shapeBuffer,  0, Context3DVertexBufferFormat.FLOAT_3); // va0 contains x,y,z
                context.setVertexBufferAt(1, segment.shapeBuffer,  3, Context3DVertexBufferFormat.FLOAT_2); // va1 contains h,v
                context.setVertexBufferAt(2, null,  5, Context3DVertexBufferFormat.FLOAT_1); // va2 is empty
                context.setVertexBufferAt(3, null, 0, Context3DVertexBufferFormat.FLOAT_3); // va3 is empty
                context.setVertexBufferAt(4, null, 3, Context3DVertexBufferFormat.FLOAT_2); // va4 is empty
                context.setVertexBufferAt(5, null, 5, Context3DVertexBufferFormat.FLOAT_1); // va5 is empty
                context.setVertexBufferAt(6, segment.paintBuffer, 0, Context3DVertexBufferFormat.FLOAT_3); // va6 contains paint

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
        onEnterFrame();
        renderMouse();
    }

    function onDeactivate(?event:Event):Void {
        stage.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
    }

    function onEnterFrame(?event:Event):Void {
        if (showHideFunc != null) showHideFunc();
        update();
        renderPretty();
    }

    function hideSomeGlyphs():Void {
        var model:Model = models[0];
        var _glyphs:Array<Glyph> = [];
        for (ike in 0...1000) _glyphs.push(model.glyphs[Std.random(model.numGlyphs)]);
        model.toggleGlyphs(_glyphs, false);
        if (model.numVisibleGlyphs <= 0) showHideFunc = showSomeGlyphs;
    }

    function showSomeGlyphs():Void {
        var model:Model = models[0];
        var _glyphs:Array<Glyph> = [];
        for (ike in 0...1000) _glyphs.push(model.glyphs[Std.random(model.numGlyphs)]);
        model.toggleGlyphs(_glyphs, true);
        if (model.numVisibleGlyphs >= model.numGlyphs) showHideFunc = hideSomeGlyphs;
    }
}
