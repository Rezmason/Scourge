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
import net.rezmason.gl.utils.UtilitySet;
import net.rezmason.gl.OutputBuffer;
import net.rezmason.utils.FlatFont;

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
    var prompt:String;
    var caret:String;

    var fonts:Map<String, FlatFont>;

    var utils:UtilitySet;
    var bodies:Array<Body>;
    var views:Array<View>;
    var fontTextures:Map<String, GlyphTexture>;

    var mouseSystem:MouseSystem;
    var keyboardSystem:KeyboardSystem;
    var mouseMethod:RenderMethod;
    var prettyMethod:RenderMethod;
    var renderer:Renderer;
    var mainOutputBuffer:OutputBuffer;

    var splashBody:Body;
    var testBody:TestBody;
    var uiBody:UIBody;

    var container:Sprite;

    public function new(stage:Stage, fonts:Map<String, FlatFont>, text:String):Void {
        active = false;
        this.stage = stage;
        this.fonts = fonts;
        this.text = text;
        prompt =
            '§{name:br1,p:0,s:1.0}' +
            '§{name:br2,p:-0.04,s:1.2}' +
            '∂{name:breathe,period:3.5,frames:[br1,br2,br1],r:1,g:0,b:1}' +
            'Ω_rezmason§{} => ';

        caret =
            '§{name:caret1,r:1,g:1,b:1}' +
            '§{name:caret2,r:0,g:0,b:0}' +
            '∂{name:caret,period:1,frames:[caret1,caret2],i:1} §{}';

        utils = new UtilitySet(stage, onCreate);
    }

    function onCreate():Void {
        makeFontTextures();
        container = new Sprite();
        stage.addChild(container);
        mouseSystem = new MouseSystem(utils.drawUtil, stage, interact);
        keyboardSystem = new KeyboardSystem(stage, interact);
        // container.addChild(mouseSystem.view);
        renderer = new Renderer(utils.drawUtil);
        mainOutputBuffer = utils.drawUtil.getMainOutputBuffer();
        prettyMethod = new PrettyMethod(utils.programUtil);
        mouseMethod = new MouseMethod(utils.programUtil);
        updateTimer = new Timer(1000 / 30);
        makeScene();

        addListeners();
        onActivate();

        // utils.drawUtil.addRenderCall(new HappyPlace(utils, fontTextures['full']).render);
        // utils.drawUtil.addRenderCall(new AGALAquarium(utils, fontTextures['full']).render);
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
        testBody = new TestBody(_id++, utils.bufferUtil, fontTextures['full'], mouseSystem.invalidate);
        bodies.push(testBody);
        views.push({body:testBody, rect:new Rectangle(0, 0, 0.6, 1)});
        /**/

        //*
        uiBody = new UIBody(_id++, utils.bufferUtil, fontTextures['full'], mouseSystem.invalidate);
        bodies.push(uiBody);

        var uiRect:Rectangle = new Rectangle(0.6, 0, 0.4, 1);
        uiRect.inflate(-0.025, -0.1);

        views.push({body:uiBody, rect:uiRect});
        uiBody.updateText(text + prompt + caret);
        /**/

        /*
        var alphabetBody:Body = new AlphabetBody(_id++, utils.bufferUtil, fontTextures['full'], mouseSystem.invalidate);
        bodies.push(alphabetBody);
        views.push({body:alphabetBody, rect:new Rectangle(0, 0, 1, 1)});
        /**/

        /*
        splashBody = new SplashBody(_id++, utils.bufferUtil, fontTextures['full'], mouseSystem.invalidate);
        bodies.push(splashBody);
        views.push({body:splashBody, rect:new Rectangle(0, 0, 1, 1)});
        /**/
    }

    function addListeners():Void {
        // OLD - stage.addEventListener(Event.RESIZE, onResize);
        stage.addEventListener(Event.ACTIVATE, onActivate);
        stage.addEventListener(Event.DEACTIVATE, onDeactivate);

        utils.drawUtil.addRenderCall(onRender);

        mouseSystem.view.addEventListener(MouseEvent.CLICK, onMouseViewClick);
    }

    function onRender(width:Int, height:Int):Void {
        if (this.width == -1 || this.width != width || this.height == -1 || this.height != height) {
            this.width = width;
            this.height = height;
            onResize();
        }

        if (active) {
            if (mouseSystem.invalid) {
                renderer.render(bodies, mouseMethod, mouseSystem.outputBuffer);
                mouseSystem.readOutputBuffer();
            }

            renderer.render(bodies, prettyMethod, mainOutputBuffer);
        }
    }

    function onResize(?event:Event):Void {
        var width:Int = stage.stageWidth;
        var height:Int = stage.stageHeight;

        #if js
            stage.width = width;
            stage.height = height;
            container.scaleX = 1 / stage.scaleX;
            container.scaleY = 1 / stage.scaleY;
        #end

        for (view in views) view.body.adjustLayout(width, height, view.rect);
        mouseSystem.setSize(width, height);
        mainOutputBuffer.resize(width, height);
    }

    function onActivate(?event:Event):Void {
        if (active) return;
        active = true;

        updateTimer.addEventListener(TimerEvent.TIMER, onTimer);
        lastTimeStamp = HaxeTimer.stamp();
        updateTimer.start();
        onResize();
        onTimer();
    }

    function onDeactivate(?event:Event):Void {
        if (!active) return;
        active = false;

        updateTimer.removeEventListener(TimerEvent.TIMER, onTimer);
        updateTimer.stop();

        keyboardSystem.focusBodyID = -1;
    }

    function onTimer(?event:Event):Void {
        var timeStamp:Float = HaxeTimer.stamp();
        update(timeStamp - lastTimeStamp);
        lastTimeStamp = timeStamp;
    }

    function onMouseViewClick(?event:Event):Void {
        mouseSystem.invalidate();
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

    function interact(bodyID:Int, glyphID:Int, interaction:Interaction):Void {

        var targetView:View = null;

        if (bodyID >= 0 && bodyID < bodies.length) targetView = views[bodyID];

        switch (interaction) {
            case MOUSE(type, oX, oY):
                if (targetView == null) {
                    for (view in views) {
                        if (!view.body.catchMouseInRect) continue;
                        if (view.rect.contains(oX / stage.stageWidth, oY / stage.stageHeight)) {
                            glyphID = -1;
                            bodyID = view.body.id;
                            targetView = views[bodyID];
                            break;
                        }
                    }
                }

                if (type == CLICK) keyboardSystem.focusBodyID = bodyID;

                if (targetView != null) {
                    var nX:Float = (oX / stage.stageWidth  - targetView.rect.x) / targetView.rect.width;
                    var nY:Float = (oY / stage.stageHeight - targetView.rect.y) / targetView.rect.height;
                    interaction = MOUSE(type, nX, nY);
                }

            case _:
        }

        if (targetView != null) targetView.body.interact(glyphID, interaction);
    }
}
