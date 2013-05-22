package net.rezmason.scourge.textview;

import nme.display.Stage;
import nme.events.Event;
import nme.events.MouseEvent;
import nme.events.TimerEvent;
import nme.geom.Matrix3D;
import nme.geom.Rectangle;
import nme.geom.Vector3D;
import nme.utils.Timer;

import net.rezmason.utils.FlatFont;
import net.rezmason.scourge.textview.core.*;
import net.rezmason.scourge.textview.rendermethods.*;
import net.rezmason.scourge.textview.utils.UtilitySet;

using net.rezmason.scourge.textview.core.GlyphUtils;

typedef HaxeTimer = haxe.Timer;
typedef View = {rect:Rectangle, body:Body};

class TextDemo {

    var stage:Stage;

    var renderer:Renderer;
    var mouseSystem:MouseSystem;

    var utils:UtilitySet;
    var testBody:TestBody;
    var uiBody:UIBody;
    var splashBody:Body;
    var bodies:Array<Body>;
    var views:Array<View>;
    var fonts:Map<String, FlatFont>;
    var fontTextures:Map<String, GlyphTexture>;
    //var showHideFunc:Void->Void;
    var prettyMethod:RenderMethod;
    var mouseMethod:RenderMethod;
    var text:String;
    var updateTimer:Timer;
    var lastTimeStamp:Float;

    public function new(stage:Stage, fonts:Map<String, FlatFont>, text:String):Void {
        this.stage = stage;
        this.fonts = fonts;
        this.text = text;
        //showHideFunc = hideSomeGlyphs;

        utils = new UtilitySet(stage, onCreate);
    }

    function onCreate():Void {
        makeFontTextures();
        mouseSystem = new MouseSystem(stage, interact);
        stage.addChild(mouseSystem.view);
        renderer = new Renderer(utils.drawUtil, mouseSystem);
        prettyMethod = new PrettyMethod(utils.programUtil);
        mouseMethod = new MouseMethod(utils.programUtil);
        updateTimer = new Timer(1000 / 30);
        makeScene();
        addListeners();
        onActivate();
    }

    function addListeners():Void {
        stage.addEventListener(Event.RESIZE, onResize);
        stage.addEventListener(Event.ACTIVATE, onActivate);
        stage.addEventListener(Event.DEACTIVATE, onDeactivate);

        mouseSystem.view.addEventListener(MouseEvent.CLICK, onMouseViewClick);
    }

    function makeFontTextures():Void {
        fontTextures = new Map();

        for (key in fonts.keys()) {
            fontTextures[key] = new GlyphTexture(utils.textureUtil, fonts[key]);
        }
    }

    function makeScene():Void {

        bodies = [];
        var _id:Int = 0;
        views = [];

        /*
        testBody = new TestBody(_id++, utils.bufferUtil, fontTextures["full"]);
        bodies.push(testBody);
        views.push({body:testBody, rect:new Rectangle(0, 0, 0.6, 1)});
        /**/

        //*
        uiBody = new UIBody(_id++, utils.bufferUtil, fontTextures["full"]);
        bodies.push(uiBody);

        var uiRect:Rectangle = new Rectangle(0.6, 0, 0.4, 1);
        uiRect.inflate(-0.025, -0.1);

        views.push({body:uiBody, rect:uiRect});
        uiBody.updateText(text);
        /**/

        /*
        var alphabetBody:Body = new AlphabetBody(_id++, utils.bufferUtil, fontTextures["full"]);
        bodies.push(alphabetBody);
        views.push({body:alphabetBody, rect:new Rectangle(0, 0, 1, 1)});
        /**/

        /*
        splashBody = new SplashBody(_id++, utils.bufferUtil, fontTextures["full"]);
        bodies.push(splashBody);
        views.push({body:splashBody, rect:new Rectangle(0, 0, 1, 1)});
        /**/
    }

    function update(delta:Float):Void {

        var numX:Float = (stage.mouseX / stage.stageWidth) * 2 - 1;
        var numY:Float = (stage.mouseY / stage.stageHeight) * 2 - 1;

        var bodyMat:Matrix3D;

        if (testBody != null) {
            bodyMat = testBody.transform;
            bodyMat.identity();
            spinBody(testBody, numX, numY);
            bodyMat.appendTranslation(0, 0, 0.5);
        }

        if (splashBody != null) {
            bodyMat = splashBody.transform;
            bodyMat.identity();
            spinBody(splashBody, 0, 0.5);
            spinBody(splashBody, numX * -0.04, 0.08);
            bodyMat.appendTranslation(0, 0.5, 0.5);
        }

        //if (uiBody != null) uiBody.scrollTextToRatio(stage.mouseY / stage.stageHeight);

        /*
        var divider:Float = stage.mouseX / stage.stageWidth;
        views[0].rect.right = divider;
        views[1].rect.left  = divider;

        for (view in views) view.body.adjustLayout(stage.stageWidth, stage.stageHeight, view.rect);
        /**/

        for (body in bodies) body.update(delta);
    }

    function spinBody(body:Body, numX:Float, numY:Float):Void {
        body.transform.appendRotation(-numX * 360 - 180     , Vector3D.Z_AXIS);
        body.transform.appendRotation(-numY * 360 - 180 + 90, Vector3D.X_AXIS);
    }

    function interact(bodyID:Int, glyphID:Int, interaction:Interaction, stageX:Float, stageY:Float/*, delta:Float*/):Void {
        if (bodyID >= bodies.length) return;
        var view:View = views[bodyID];
        var x:Float = (stageX / stage.stageWidth  - view.rect.x) / view.rect.width;
        var y:Float = (stageY / stage.stageHeight - view.rect.y) / view.rect.height;
        view.body.interact(glyphID, interaction, x, y/*, delta*/);
    }

    function onMouseViewClick(?event:Event):Void {
        renderer.render(bodies, mouseMethod, RenderDestination.MOUSE);
    }

    function onResize(?event:Event):Void {
        for (view in views) view.body.adjustLayout(stage.stageWidth, stage.stageHeight, view.rect);
        mouseSystem.setSize(stage.stageWidth, stage.stageHeight);
        renderer.setSize(stage.stageWidth, stage.stageHeight);
    }

    function onActivate(?event:Event):Void {
        stage.addEventListener(Event.ENTER_FRAME, onEnterFrame);
        updateTimer.addEventListener(TimerEvent.TIMER, onTimer);
        lastTimeStamp = HaxeTimer.stamp();
        updateTimer.start();
        onResize();
        onTimer();
        onEnterFrame();
        renderer.render(bodies, mouseMethod, RenderDestination.MOUSE);
    }

    function onDeactivate(?event:Event):Void {
        updateTimer.removeEventListener(TimerEvent.TIMER, onTimer);
        updateTimer.stop();
        stage.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
    }

    function onEnterFrame(?event:Event):Void {
        renderer.render(bodies, prettyMethod, RenderDestination.SCREEN);
    }

    function onTimer(?event:Event):Void {
        //if (showHideFunc != null) showHideFunc();
        var timeStamp:Float = HaxeTimer.stamp();
        update(timeStamp - lastTimeStamp);
        lastTimeStamp = timeStamp;
    }

    /*
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
    */
}
