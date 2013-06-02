package net.rezmason.scourge.textview;

import flash.display.Sprite;
import flash.display.Stage;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.events.TimerEvent;
import flash.geom.Matrix3D;
import flash.geom.Rectangle;
import flash.geom.Vector3D;
import flash.utils.Timer;
import net.rezmason.scourge.textview.core.*;
import net.rezmason.scourge.textview.rendermethods.*;
import net.rezmason.scourge.textview.utils.UtilitySet;
import net.rezmason.scourge.textview.core.Types;
import net.rezmason.utils.FlatFont;

using net.rezmason.scourge.textview.core.GlyphUtils;

typedef HaxeTimer = haxe.Timer;
typedef View = {rect:Rectangle, body:Body};

class TextDemo {

    var active:Bool;
    var stage:Stage;
    var width:Int;
    var height:Int;

    var updateTimer:Timer;
    var lastTimeStamp:Float;

    var text:String;

    var fonts:Map<String, FlatFont>;

    var utils:UtilitySet;
    var bodies:Array<Body>;
    var views:Array<View>;
    var fontTextures:Map<String, GlyphTexture>;

    var mouseSystem:MouseSystem;
    var mouseMethod:RenderMethod;
    var prettyMethod:RenderMethod;
    var renderer:Renderer;

    var hitAreasInvalid:Bool;

    var splashBody:Body;
    var testBody:TestBody;
    var uiBody:UIBody;

    var container:Sprite;

    public function new(stage:Stage, fonts:Map<String, FlatFont>, text:String):Void {
        active = false;
        this.stage = stage;
        this.fonts = fonts;
        this.text = text;

        utils = new UtilitySet(stage, onCreate);
    }

    function onCreate():Void {
        makeFontTextures();
        container = new Sprite();
        stage.addChild(container);
        mouseSystem = new MouseSystem(stage, interact);
        // container.addChild(mouseSystem.view);
        renderer = new Renderer(utils.drawUtil, mouseSystem);
        prettyMethod = new PrettyMethod(utils.programUtil);
        mouseMethod = new MouseMethod(utils.programUtil);
        updateTimer = new Timer(1000 / 30);
        makeScene();
        addListeners();
        onActivate();
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

        //*
        testBody = new TestBody(_id++, utils.bufferUtil, fontTextures["full"], redrawHitAreas);
        bodies.push(testBody);
        views.push({body:testBody, rect:new Rectangle(0, 0, 0.6, 1)});
        /**/

        //*
        uiBody = new UIBody(_id++, utils.bufferUtil, fontTextures["full"], redrawHitAreas);
        bodies.push(uiBody);

        var uiRect:Rectangle = new Rectangle(0.6, 0, 0.4, 1);
        uiRect.inflate(-0.025, -0.1);

        views.push({body:uiBody, rect:uiRect});
        uiBody.updateText(text);
        /**/

        /*
        var alphabetBody:Body = new AlphabetBody(_id++, utils.bufferUtil, fontTextures["full"], redrawHitAreas);
        bodies.push(alphabetBody);
        views.push({body:alphabetBody, rect:new Rectangle(0, 0, 1, 1)});
        /**/

        /*
        splashBody = new SplashBody(_id++, utils.bufferUtil, fontTextures["full"], redrawHitAreas);
        bodies.push(splashBody);
        views.push({body:splashBody, rect:new Rectangle(0, 0, 1, 1)});
        /**/

        utils.drawUtil.addRenderCall(onRender);
        // utils.drawUtil.addRenderCall(new HappyPlace(utils, fontTextures["full"]).render);
    }

    function addListeners():Void {
        // OLD - stage.addEventListener(Event.RESIZE, onResize);
        stage.addEventListener(Event.ACTIVATE, onActivate);
        stage.addEventListener(Event.DEACTIVATE, onDeactivate);

        // mouseSystem.view.addEventListener(MouseEvent.CLICK, onMouseViewClick);
    }

    function onRender(width:Int, height:Int):Void {
        if (this.width == -1 || this.width != width || this.height == -1 || this.height != height) {
            this.width = width;
            this.height = height;
            onResize();
        }

        if (active) {
            if (hitAreasInvalid) {
                renderer.render(bodies, mouseMethod, RenderDestination.MOUSE);
                hitAreasInvalid = false;
            }

            renderer.render(bodies, prettyMethod, RenderDestination.SCREEN);
        }
    }

    function onResize(?event:Event):Void {
        #if js
            stage.width = stage.stageWidth;
            stage.height = stage.stageHeight;
            container.scaleX = 1 / stage.scaleX;
            container.scaleY = 1 / stage.scaleY;
        #end

        for (view in views) view.body.adjustLayout(stage.stageWidth, stage.stageHeight, view.rect);
        mouseSystem.setSize(stage.stageWidth, stage.stageHeight);
        renderer.setSize(stage.stageWidth, stage.stageHeight);
    }

    function onActivate(?event:Event):Void {
        if (active) return;
        active = true;

        updateTimer.addEventListener(TimerEvent.TIMER, onTimer);
        lastTimeStamp = HaxeTimer.stamp();
        updateTimer.start();
        onResize();
        onTimer();
        redrawHitAreas();
    }

    function onDeactivate(?event:Event):Void {
        if (!active) return;
        active = false;

        updateTimer.removeEventListener(TimerEvent.TIMER, onTimer);
        updateTimer.stop();
    }

    function onTimer(?event:Event):Void {
        var timeStamp:Float = HaxeTimer.stamp();
        update(timeStamp - lastTimeStamp);
        lastTimeStamp = timeStamp;
    }

    function redrawHitAreas():Void {
        hitAreasInvalid = true;
    }

    function onMouseViewClick(?event:Event):Void {
        redrawHitAreas();
    }

    function update(delta:Float):Void {

        var numX:Float = (stage.mouseX / stage.stageWidth) * 2 - 1;
        var numY:Float = (stage.mouseY / stage.stageHeight) * 2 - 1;

        if (Math.isNaN(numX)) numX = 0;
        if (Math.isNaN(numY)) numY = 0;

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
        view.body.interact(glyphID, interaction, x, y); // , delta
    }
}
