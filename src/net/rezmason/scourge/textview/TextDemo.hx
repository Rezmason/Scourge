package net.rezmason.scourge.textview;

import com.adobe.utils.PerspectiveMatrix3D;
import haxe.Timer;
import nme.display.Stage;
import nme.events.Event;
import nme.events.MouseEvent;
import nme.geom.Matrix3D;
import nme.geom.Rectangle;
import nme.geom.Vector3D;

import net.rezmason.utils.FlatFont;
import net.rezmason.scourge.textview.utils.UtilitySet;

class TextDemo {

    inline static var SPACE_WIDTH:Float = 2.0;
    inline static var SPACE_HEIGHT:Float = 2.0;
    inline static var FONT_SIZE:Float = 0.04;

    var stage:Stage;

    var mode:RenderMode;

    var renderer:Renderer;

    var projection:PerspectiveMatrix3D;
    var utils:UtilitySet;
    var scene:Scene;
    var showHideFunc:Void->Void;
    var font:FlatFont;
    var glyphTexture:GlyphTexture;
    var prettyStyle:Style;
    var mouseStyle:Style;

    public function new(stage:Stage, font:FlatFont):Void {
        this.stage = stage;
        this.font = font;
        showHideFunc = hideSomeGlyphs;
        utils = new UtilitySet(stage.stage3Ds[0], onCreate);
    }

    function onCreate():Void {
        glyphTexture = new FoggyGlyphTexture(utils.textureUtil, font, FONT_SIZE);
        renderer = new Renderer(utils.drawUtil);
        stage.addChild(renderer.mouseView);
        prettyStyle = new PrettyStyle(utils.programUtil);
        mouseStyle = new MouseStyle(utils.programUtil);
        makeScene();
        addListeners();
        onActivate();
    }

    function addListeners():Void {
        stage.addEventListener(Event.RESIZE, onResize);
        stage.addEventListener(Event.ACTIVATE, onActivate);
        stage.addEventListener(Event.DEACTIVATE, onDeactivate);
        stage.addEventListener(MouseEvent.CLICK, onClick);
        stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
    }

    function makeScene():Void {

        scene = new Scene();
        projection = new PerspectiveMatrix3D();

        projection.perspectiveLH(2, 2, 1, 2);
        //projection.orthoLH(2, 2, 1, 2);

        var model:Model = new TestModel(0, utils.bufferUtil, glyphTexture);
        model.matrix = new Matrix3D();
        //model.scissorRectangle = new Rectangle(0, 0, stage.stageWidth, stage.stageHeight);
        scene.models.push(model);
    }

    function update(?event:Event):Void {

        var numX:Float = (stage.mouseX / stage.stageWidth) * 2 - 1;
        var numY:Float = (stage.mouseY / stage.stageHeight) * 2 - 1;
        var numT:Float = (Timer.stamp() % 10) / 10;

        var cX:Float = 0.5 * Math.cos(numT * Math.PI * 2);
        var cY:Float = 0.5 * Math.sin(numT * Math.PI * 2);
        var cZ:Float = 0.1 * Math.sin(numT * Math.PI * 2 * 5);

        var model:Model = scene.models[0];
        var modelMat:Matrix3D = model.matrix;
        modelMat.identity();
        spinModel(model, numX, numY);
        //modelMat.appendTranslation(cX, cY, cZ);
        modelMat.appendTranslation(0, 0, 0.5);

        //var vec:Vector3D = new Vector3D();
        //scene.cameraMat.copyColumnTo(2, vec);
        //vec.x += numX;
        //vec.y += -numY;
        //scene.cameraMat.copyColumnFrom(2, vec);
    }

    function spinModel(model:Model, numX:Float, numY:Float):Void {
        model.matrix.appendRotation(-numX * 360 - 180, Vector3D.Z_AXIS);
        model.matrix.appendRotation(-numY * 360 - 180 + 90, Vector3D.X_AXIS);
    }

    function onClick(?event:Event):Void {
        renderer.render(scene, mouseStyle, RenderMode.MOUSE);
    }

    function onMouseMove(?event:Event):Void {
        renderer.mouseView.update(stage.mouseX, stage.mouseY);
    }

    function onResize(?event:Event):Void {
        var aspectRatio:Float = stage.stageWidth / stage.stageHeight;

        scene.cameraMat.identity();
        scene.cameraMat.appendScale(SPACE_WIDTH, SPACE_HEIGHT, 1);
        if (aspectRatio < 1) {
            scene.cameraMat.appendScale(1, aspectRatio, 1);
        } else {
            scene.cameraMat.appendScale(1 / aspectRatio, 1, 1);
        }
        scene.cameraMat.appendTranslation(0, 0, 1);
        scene.cameraMat.append(projection);

        renderer.setSize(stage.stageWidth, stage.stageHeight);
    }

    function onActivate(?event:Event):Void {
        stage.addEventListener(Event.ENTER_FRAME, onEnterFrame);
        onResize();
        onEnterFrame();
        renderer.render(scene, mouseStyle, RenderMode.MOUSE);
    }

    function onDeactivate(?event:Event):Void {
        stage.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
    }

    function onEnterFrame(?event:Event):Void {
        //if (showHideFunc != null) showHideFunc();
        update();
        renderer.render(scene, prettyStyle, RenderMode.SCREEN);
    }

    function hideSomeGlyphs():Void {
        var model:Model = scene.models[0];
        var _glyphs:Array<Glyph> = [];
        for (ike in 0...1000) _glyphs.push(model.glyphs[Std.random(model.numGlyphs)]);
        model.toggleGlyphs(_glyphs, false);
        if (model.numVisibleGlyphs <= 0) showHideFunc = showSomeGlyphs;
    }

    function showSomeGlyphs():Void {
        var model:Model = scene.models[0];
        var _glyphs:Array<Glyph> = [];
        for (ike in 0...1000) _glyphs.push(model.glyphs[Std.random(model.numGlyphs)]);
        model.toggleGlyphs(_glyphs, true);
        if (model.numVisibleGlyphs >= model.numGlyphs) showHideFunc = hideSomeGlyphs;
    }
}
