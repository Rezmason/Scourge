package net.rezmason.scourge.textview.core;

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
#if hxtelemetry import hxtelemetry.HxTelemetry; #end

using Lambda;

class Engine extends Module {

    var active:Bool;
    public var width(default, null):Int;
    public var height(default, null):Int;
    public var ready(default, null):Bool;
    public var readySignal(default, null):Zig<Void->Void>;

    var glSys:GLSystem;
    var glFlow:GLFlowControl;
    var bodiesByID:Map<Int, Body>;
    var scenes:Array<Scene>;
    
    var compositor:Compositor;
    var mouseSystem:MouseSystem;
    var keyboardSystem:KeyboardSystem;
    var mouseMethod:RenderMethod;
    var prettyMethod:RenderMethod;
    var presentationMethod:RenderMethod;
    #if debug_graphics public var debugGraphics(get, null):DebugGraphics; #end
    #if hxtelemetry var telemetry:HxTelemetry; #end

    public function new(glFlow:GLFlowControl):Void {
        #if hxtelemetry telemetry = new Present(HxTelemetry); #end
        super();
        this.glFlow = glFlow;
        active = false;
        ready = false;
        readySignal = new Zig();
        glSys = new Present(GLSystem);
        
        width = 1;
        height = 1;
        bodiesByID = new Map();
        scenes = [];

        initInteractionSystems();
        initRenderMethods();
        addListeners();
    }

    public function addScene(scene:Scene):Void {
        #if debug assertReady(); #end
        if (!scenes.has(scene)) {
            scenes.push(scene);
            scene.redrawHitSignal.add(updateMouseSystem);
            scene.invalidatedSignal.add(invalidateScene);
            scene.resize(width, height);
            invalidateScene();
        }
    }

    public function removeScene(scene:Scene):Void {
        #if debug assertReady(); #end
        if (scenes.has(scene)) {
            scenes.remove(scene);
            scene.redrawHitSignal.remove(updateMouseSystem);
            scene.invalidatedSignal.remove(invalidateScene);
            invalidateScene();
        }
    }

    public function setKeyboardFocus(body:Body):Void {
        #if debug assertReady(); #end
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
    override public function update(milliseconds):Void onTimer(milliseconds / 1000);

    // override public function onRenderContextLost() {}
    // override public function onRenderContextRestored(_) {}
    // override public function onTextInput(text) {}

    function initInteractionSystems():Void {
        mouseSystem = new MouseSystem();
        mouseSystem.refreshSignal.add(renderMouse);
        mouseSystem.interactSignal.add(handleInteraction);

        keyboardSystem = new KeyboardSystem();
        keyboardSystem.interactSignal.add(handleInteraction);
    }

    function initRenderMethods():Void {
        compositor = new Compositor();

        prettyMethod = new PrettyMethod();
        mouseMethod = new MouseMethod();
        presentationMethod = prettyMethod;

        prettyMethod.loadedSignal.add(checkReadiness);
        mouseMethod.loadedSignal.add(checkReadiness);

        prettyMethod.load();
        mouseMethod.load();
    }

    function checkReadiness():Void {
        if (!ready && prettyMethod.programLoaded && mouseMethod.programLoaded) {
            ready = true;
            #if flash flash.Lib.current.stage.dispatchEvent(new flash.events.Event('resize')); #end
            var window = Application.current.window;
            this.width = window.width;
            this.height = window.height;
            activate();
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
            #if hxtelemetry
                var stack = telemetry.unwind_stack();
                telemetry.start_timing('.render');
            #end
            drawFrame(presentationMethod, compositor.inputBuffer);
            compositor.draw();
            #if hxtelemetry
                telemetry.end_timing('.render');
                telemetry.rewind_stack(stack);
                telemetry.advance_frame();
            #end
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
                    for (body in scene.bodies) {
                        body.upload();
                        if (body.numGlyphs > 0) method.drawBody(body);
                    }
                }
                method.finish();
            }
        }
    }

    function setSize(width:Int, height:Int):Void {
        #if debug assertReady(); #end
        this.width = width;
        this.height = height;
        for (scene in scenes) scene.resize(width, height);
        mouseSystem.setSize(width, height);
        compositor.setSize(width, height);
    }

    function activate():Void {
        #if debug assertReady(); #end
        if (active) return;
        active = true;
        setSize(width, height);
        regulateUserInput();
    }

    function deactivate():Void {
        #if debug assertReady(); #end
        if (!active) return;
        active = false;
        regulateUserInput();
    }

    function regulateUserInput():Void {
        keyboardSystem.active = active && glSys.connected;
        mouseSystem.active = active && glSys.connected;
    }

    function onTimer(delta:Float):Void {
        if (!active) return;
        #if hxtelemetry
            var stack = telemetry.unwind_stack();
            telemetry.start_timing('.update');
        #end
        fetchBodies();
        for (body in bodiesByID) body.update(delta);
        #if hxtelemetry
            telemetry.end_timing('.update');
            telemetry.rewind_stack(stack);
        #end
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
            haxe.Timer.delay(glFlow.connect, mils);
        }
    }

    function handleInteraction(bodyID:Null<Int>, glyphID:Null<Int>, interaction:Interaction):Void {
        fetchBodies();
        var target:Body = bodiesByID[bodyID];

        switch (interaction) {
            case MOUSE(type, oX, oY):
                if (type == CLICK) keyboardSystem.focusBodyID = bodyID;

                if (target != null) {
                    var camera = target.scene.camera;
                    var rect:Rectangle = camera.rect;
                    var nX:Float = (oX / width  - rect.x) / rect.width;
                    var nY:Float = (oY / height - rect.y) / rect.height;
                    nX /= camera.scaleX;
                    nY /= camera.scaleY;
                    interaction = MOUSE(type, nX, nY);
                }
            case KEYBOARD(type, code, modifier) if (code == SPACE):
                presentationMethod = (modifier.altKey && type != KEY_UP) ? mouseMethod : prettyMethod;
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

    #if debug inline function assertReady():Void if (!ready) throw "Engine hasn't initialized yet."; #end

    #if debug_graphics inline function get_debugGraphics() return compositor.debugGraphics; #end
}
