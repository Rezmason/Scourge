package net.rezmason.scourge.textview.core;

import haxe.Timer;

import lime.app.Application;
import lime.app.Module;
import lime.ui.KeyCode;
import lime.ui.KeyModifier;

import net.rezmason.gl.GLTypes;
import net.rezmason.gl.OutputBuffer;
import net.rezmason.gl.GLFlowControl;
import net.rezmason.gl.GLSystem;
import net.rezmason.scourge.textview.core.rendermethods.*;
import net.rezmason.utils.Zig;
import net.rezmason.utils.santa.Present;

using Lambda;

class Engine extends Module {

    var active:Bool;
    public var timestep(default, set):Float;
    public var width(default, null):Int;
    public var height(default, null):Int;
    public var ready(default, null):Bool;
    public var readySignal(default, null):Zig<Void->Void>;

    var updateTimer:Timer;
    var lastTimeStamp:Float;

    var glSys:GLSystem;
    var glFlow:GLFlowControl;
    var bodiesByID:Map<Int, Body>;
    var scenes:Array<Scene>;
    
    var postProcess:PostProcessor;
    var mouseSystem:MouseSystem;
    var keyboardSystem:KeyboardSystem;
    var mouseMethod:RenderMethod;
    var prettyMethod:RenderMethod;
    var presentationMethod:RenderMethod;

    public function new(glFlow:GLFlowControl):Void {
        super();
        this.glFlow = glFlow;
        active = false;
        ready = false;
        readySignal = new Zig();
        glSys = new Present(GLSystem);
        
        width = 1;
        height = 1;
        timestep = 1000 / 60;
        bodiesByID = new Map();
        scenes = [];

        readySignal.add(onReady);
        
        initInteractionSystems();
        initRenderMethods();
        addListeners();
    }

    public function set_timestep(f:Float):Float return timestep = (f >= 0 ? f : 0);

    public function addScene(scene:Scene):Void {
        #if debug readyCheck(); #end
        if (!scenes.has(scene)) {
            scenes.push(scene);
            scene.redrawHitSignal.add(updateMouseSystem);
            scene.invalidatedSignal.add(invalidateScene);
            scene.resize(width, height);
            invalidateScene();
        }
    }

    public function removeScene(scene:Scene):Void {
        #if debug readyCheck(); #end
        if (scenes.has(scene)) {
            scenes.remove(scene);
            scene.redrawHitSignal.remove(updateMouseSystem);
            scene.invalidatedSignal.remove(invalidateScene);
            invalidateScene();
        }
    }

    public function setKeyboardFocus(body:Body):Void {
        #if debug readyCheck(); #end
        fetchBodies();
        if (bodiesByID[body.id] == body) keyboardSystem.focusBodyID = body.id;
    }

    override public function onKeyDown(_, keyCode, modifier) keyboardSystem.onKeyDown(keyCode, modifier);
    override public function onKeyUp(_, keyCode, modifier) keyboardSystem.onKeyUp(keyCode, modifier);
    override public function onMouseMove(_, x, y) mouseSystem.onMouseMove(x, y);
    override public function onMouseDown(_, x, y, button) mouseSystem.onMouseDown(x, y, button);
    override public function onMouseUp(_, x, y, button) mouseSystem.onMouseUp(x, y, button);
    override public function onWindowActivate(_) activate();
    override public function onWindowDeactivate(_) deactivate();
    override public function onWindowEnter(_) activate();
    override public function onWindowLeave(_) deactivate();
    override public function onWindowResize(_, width, height) setSize(width, height);

    // override public function onRenderContextLost() {}
    // override public function onRenderContextRestored(_) {}
    // override public function onTextInput(text) {}

    function onReady():Void {
        #if flash flash.Lib.current.stage.dispatchEvent(new flash.events.Event('resize')); #end
        var window = Application.current.window;
        setSize(window.width, window.height);
        activate();
    }

    function initInteractionSystems():Void {
        mouseSystem = new MouseSystem();
        mouseSystem.refreshSignal.add(renderMouse);
        mouseSystem.interactSignal.add(handleInteraction);

        keyboardSystem = new KeyboardSystem();
        keyboardSystem.interactSignal.add(handleInteraction);
    }

    function initRenderMethods():Void {
        postProcess = new PostProcessor();

        prettyMethod = new PrettyMethod();
        mouseMethod = new MouseMethod();
        presentationMethod = prettyMethod;

        prettyMethod.loadedSignal.add(onMethodLoaded);
        mouseMethod.loadedSignal.add(onMethodLoaded);

        prettyMethod.load();
        mouseMethod.load();
    }

    function onMethodLoaded():Void {
        if (!ready && prettyMethod.programLoaded && mouseMethod.programLoaded) {
            ready = true;
            readySignal.dispatch();
        }
    }

    function addListeners():Void {
        glFlow.onRender = onRender;
        glFlow.onDisconnect = onDisconnect;
        glFlow.onConnect = onConnect;
    }

    function onRender(width:Int, height:Int):Void {
        if (active) {
            drawFrame(presentationMethod, postProcess.inputBuffer);
            postProcess.draw();
        }
    }

    function onDisconnect():Void {
        regulateUserInput();
    }

    function onConnect():Void {
        regulateUserInput();
    }

    function renderMouse():Void {
        drawFrame(mouseMethod, mouseSystem.outputBuffer);
    }

    function drawFrame(method:RenderMethod, outputBuffer:OutputBuffer):Void {
        //trace('rendering with method ${Std.is(method, PrettyMethod) ? "pretty" : "mouse"}');
        if (glSys.connected) {
            if (method == null) {
                trace('Null method.');
            } else {
                method.start(outputBuffer);
                for (scene in scenes) {
                    for (body in scene.bodies) if (body.numGlyphs > 0) method.drawBody(body);
                }
                method.finish();
            }
        }
    }

    function setSize(width:Int, height:Int):Void {
        #if debug readyCheck(); #end
        this.width = width;
        this.height = height;
        for (scene in scenes) scene.resize(width, height);
        mouseSystem.setSize(width, height);
        postProcess.setSize(width, height);
    }

    function activate():Void {
        #if debug readyCheck(); #end
        if (active) return;
        active = true;

        updateTimer = new Timer(Std.int(timestep));
        updateTimer.run = onTimer;
        lastTimeStamp = Timer.stamp();
        setSize(width, height);
        onTimer();
        regulateUserInput();
    }

    function deactivate():Void {
        #if debug readyCheck(); #end
        if (!active) return;
        active = false;
        updateTimer.stop();
        updateTimer = null;
        regulateUserInput();
    }

    function regulateUserInput():Void {
        keyboardSystem.active = active && glSys.connected;
        mouseSystem.active = active && glSys.connected;
    }

    function onTimer():Void {
        var timeStamp:Float = Timer.stamp();
        var delta:Float = timeStamp - lastTimeStamp;
        fetchBodies();
        for (body in bodiesByID) body.update(delta);
        lastTimeStamp = timeStamp;
    }

    function updateMouseSystem():Void {
        fetchBodies();
        var rectsByBodyID:Map<Int, Rectangle> = new Map();
        for (scene in scenes) if (scene.focus != null) rectsByBodyID[scene.focus.id] = scene.camera.rect;
        mouseSystem.setRectRegions(rectsByBodyID);
        mouseSystem.invalidate();
    }

    function testDisconnect(mils:UInt):Void {
        if (glSys.connected) {
            glFlow.disconnect();
            Timer.delay(glFlow.connect, mils);
        }
    }

    function handleInteraction(bodyID:Null<Int>, glyphID:Null<Int>, interaction:Interaction):Void {
        fetchBodies();
        var target:Body = bodiesByID[bodyID];

        switch (interaction) {
            case MOUSE(type, oX, oY):
                if (type == CLICK) keyboardSystem.focusBodyID = bodyID;

                if (target != null) {
                    var rect:Rectangle = target.scene.camera.rect;
                    var nX:Float = (oX / width  - rect.x) / rect.width;
                    var nY:Float = (oY / height - rect.y) / rect.height;
                    interaction = MOUSE(type, nX, nY);
                }
            case KEYBOARD(type, code, modifier) if (code == SPACE && modifier.altKey):
                presentationMethod = type != KEY_UP ? mouseMethod : prettyMethod;
            case _:
        }

        if (target != null) target.interactionSignal.dispatch(glyphID, interaction);
    }

    inline function invalidateScene():Void bodiesByID = null;

    inline function fetchBodies():Void {
        if (bodiesByID == null) {
            bodiesByID = new Map();
            for (scene in scenes) for (body in scene.bodies) bodiesByID[body.id] = body;
        }
    }

    #if debug inline function readyCheck():Void if (!ready) throw "Engine hasn't initialized yet."; #end
}
