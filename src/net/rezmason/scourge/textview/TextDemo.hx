package net.rezmason.scourge.textview;

import haxe.ds.StringMap;

import haxe.Timer;
import nme.display.Stage;
import nme.events.Event;
import nme.events.MouseEvent;
import nme.geom.Matrix3D;
import nme.geom.Rectangle;
import nme.geom.Vector3D;

import net.rezmason.utils.FlatFont;
import net.rezmason.scourge.textview.core.*;
import net.rezmason.scourge.textview.rendermethods.*;
import net.rezmason.scourge.textview.utils.UtilitySet;

using net.rezmason.scourge.textview.core.GlyphUtils;

typedef View = {rect:Rectangle, body:Body};

class TextDemo {

    var stage:Stage;

    var renderer:Renderer;

    var utils:UtilitySet;
    var testBody:Body;
    var uiBody:UIBody;
    var bodies:Array<Body>;
    var views:Array<View>;
    var fonts:StringMap<FlatFont>;
    var fontTextures:StringMap<GlyphTexture>;
    var showHideFunc:Void->Void;
    var prettyMethod:RenderMethod;
    var mouseMethod:RenderMethod;
    var text:String;

    public function new(stage:Stage, fonts:StringMap<FlatFont>, text:String):Void {
        this.stage = stage;
        this.fonts = fonts;
        this.text = text;
        showHideFunc = hideSomeGlyphs;
        utils = new UtilitySet(stage.stage3Ds[0], onCreate);
    }

    function onCreate():Void {
        makeFontTextures();
        renderer = new Renderer(utils.drawUtil);
        stage.addChild(renderer.mouseView);
        prettyMethod = new PrettyMethod(utils.programUtil);
        mouseMethod = new MouseMethod(utils.programUtil);
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

    function makeFontTextures():Void {
        fontTextures = new StringMap<GlyphTexture>();

        for (key in fonts.keys()) {
            fontTextures.set(key, new GlyphTexture(utils.textureUtil, fonts.get(key)));
        }
    }

    function makeScene():Void {

        bodies = [];
        views = [];

        testBody = new TestBody(0, utils.bufferUtil, fontTextures.get("full"));
        bodies.push(testBody);
        views.push({body:testBody, rect:new Rectangle(0, 0, 1, 1)});

        uiBody = new UIBody(0, utils.bufferUtil, fontTextures.get("full"));
        bodies.push(uiBody);

        var uiRect:Rectangle = new Rectangle(0.6, 0, 0.4, 1);
        uiRect.inflate(-0.025, -0.025);

        views.push({body:uiBody, rect:uiRect});
        uiBody.updateText(text);

        /*
        var alphabetBody:Body = new AlphabetBody(0, utils.bufferUtil, fontTextures.get("full"));
        bodies.push(alphabetBody);
        views.push({body:alphabetBody, rect:new Rectangle(0, 0, 1, 1)});
        /**/
    }

    function update(?event:Event):Void {

        //*
        var testBody:Body = bodies[0];
        var numX:Float = (stage.mouseX / stage.stageWidth) * 2 - 1;
        var numY:Float = (stage.mouseY / stage.stageHeight) * 2 - 1;
        var numT:Float = (Timer.stamp() % 10) / 10;

        var cX:Float = 0.5 * Math.cos(numT * Math.PI * 2);
        var cY:Float = 0.5 * Math.sin(numT * Math.PI * 2);
        var cZ:Float = 0.1 * Math.sin(numT * Math.PI * 2 * 5);

        var bodyMat:Matrix3D = testBody.transform;
        bodyMat.identity();
        spinBody(testBody, numX, numY);
        //bodyMat.appendTranslation(cX, cY, cZ);
        bodyMat.appendTranslation(0, 0, 0.5);

        var t:Float = Timer.stamp() * 4;

        for (glyph in testBody.glyphs) {
            var p:Float = (Math.cos(t * 1 + glyph.get_x() * 10) * 0.5 + 1) * 0.1;
            var s:Float = (Math.cos(t * 2 + glyph.get_x() * 20) * 0.5 + 1) * 2.0;
            glyph.set_p(p);
            glyph.set_s(s);
        }

        testBody.update();
        /**/

        //*
        var divider:Float = stage.mouseX / stage.stageWidth;
        views[0].rect.right = divider;
        views[1].rect.left  = divider;

        for (view in views) view.body.adjustLayout(stage.stageWidth, stage.stageHeight, view.rect);
        /**/

        /*
        uiBody.scrollChars(1 - stage.mouseY / stage.stageHeight);
        /**/
        uiBody.update();
    }

    function spinBody(body:Body, numX:Float, numY:Float):Void {
        body.transform.appendRotation(-numX * 360 - 180     , Vector3D.Z_AXIS);
        body.transform.appendRotation(-numY * 360 - 180 + 90, Vector3D.X_AXIS);
    }

    function onClick(?event:Event):Void {
        renderer.render(bodies, mouseMethod, RenderDestination.MOUSE);
    }

    function onMouseMove(?event:Event):Void {
        renderer.mouseView.update(stage.mouseX, stage.mouseY);
    }

    function onResize(?event:Event):Void {
        for (view in views) view.body.adjustLayout(stage.stageWidth, stage.stageHeight, view.rect);
        renderer.setSize(stage.stageWidth, stage.stageHeight);
    }

    function onActivate(?event:Event):Void {
        stage.addEventListener(Event.ENTER_FRAME, onEnterFrame);
        onResize();
        onEnterFrame();
        renderer.render(bodies, mouseMethod, RenderDestination.MOUSE);
    }

    function onDeactivate(?event:Event):Void {
        stage.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
    }

    function onEnterFrame(?event:Event):Void {
        //if (showHideFunc != null) showHideFunc();
        update();
        renderer.render(bodies, prettyMethod, RenderDestination.SCREEN);
    }

    function hideSomeGlyphs():Void {
        var body:Body = bodies[0];
        var _glyphs:Array<Glyph> = [];
        for (ike in 0...1000) _glyphs.push(body.glyphs[Std.random(body.numGlyphs)]);
        body.toggleGlyphs(_glyphs, false);
        body.update();
        if (body.numVisibleGlyphs <= 0) showHideFunc = showSomeGlyphs;
    }

    function showSomeGlyphs():Void {
        var body:Body = bodies[0];
        var _glyphs:Array<Glyph> = [];
        for (ike in 0...1000) _glyphs.push(body.glyphs[Std.random(body.numGlyphs)]);
        body.toggleGlyphs(_glyphs, true);
        body.update();
        if (body.numVisibleGlyphs >= body.numGlyphs) showHideFunc = hideSomeGlyphs;
    }
}
