package net.rezmason.hypertype.core;

import lime.app.Application;
import lime.app.Module;

import net.rezmason.gl.GLTypes;
import net.rezmason.gl.RenderTarget;
import net.rezmason.gl.GLSystem;
import net.rezmason.hypertype.core.rendermethods.*;
import net.rezmason.utils.santa.Present;
#if hxtelemetry import hxtelemetry.HxTelemetry; #end

using Lambda;

class Engine extends Module {

    var active:Bool;
    public var width(default, null):Int;
    public var height(default, null):Int;

    var glSys:GLSystem;
    var bodiesByID:Map<Int, Body>;
    var scenes:Array<Scene>;
    
    var compositor:Compositor;
    var mouseSystem:MouseSystem;
    var keyboardSystem:KeyboardSystem;
    var hitboxMethod:SceneRenderMethod;
    var sdfFontMethod:SceneRenderMethod;
    var presentationMethod:SceneRenderMethod;
    #if debug_graphics public var debugGraphics(get, null):DebugGraphics; #end
    #if hxtelemetry var telemetry:HxTelemetry; #end

    public function new():Void {
        #if hxtelemetry telemetry = new Present(HxTelemetry); #end
        super();
        active = false;
        glSys = new Present(GLSystem);
        glSys.connect();
        
        width = 1;
        height = 1;
        bodiesByID = new Map();
        scenes = [];

        initInteractionSystems();
        initSceneRenderMethods();
    }

    public function addScene(scene:Scene):Void {
        if (!scenes.has(scene)) {
            scenes.push(scene);
            scene.redrawHitSignal.add(updateMouseSystem);
            scene.invalidatedSignal.add(invalidateScene);
            scene.resize(width, height);
            invalidateScene();
            updateMouseSystem();
        }
    }

    public function removeScene(scene:Scene):Void {
        if (scenes.has(scene)) {
            scenes.remove(scene);
            scene.redrawHitSignal.remove(updateMouseSystem);
            scene.invalidatedSignal.remove(invalidateScene);
            invalidateScene();
            updateMouseSystem();
        }
    }

    public function setKeyboardFocus(body:Body):Void {
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

    override public function update(milliseconds) {
        if (!active) return;
        
        #if hxtelemetry
            var stack = telemetry.unwind_stack();
            telemetry.start_timing('.update');
        #end

        fetchBodies();
        var delta = milliseconds / 1000;
        for (body in bodiesByID) body.update(delta);
        
        #if hxtelemetry
            telemetry.end_timing('.update');
            telemetry.rewind_stack(stack);
        #end
    }

    override public function render(_) {
        if (!active) return;
            
        #if hxtelemetry
            var stack = telemetry.unwind_stack();
            telemetry.start_timing('.render');
        #end

        drawFrame(presentationMethod, compositor.inputRenderTarget);
        if (glSys.connected) compositor.draw();

        #if hxtelemetry
            telemetry.end_timing('.render');
            telemetry.rewind_stack(stack);
            telemetry.advance_frame();
        #end
    }

    override public function onRenderContextLost(_) {
        glSys.disconnect();
        regulateUserInput();
    }

    override public function onRenderContextRestored(_, _) {
        glSys.connect();
        regulateUserInput();
    }

    // override public function onTextInput(text) {}

    function initInteractionSystems():Void {
        mouseSystem = new MouseSystem();
        mouseSystem.refreshSignal.add(renderMouse);
        mouseSystem.interactSignal.add(handleInteraction);

        keyboardSystem = new KeyboardSystem();
        keyboardSystem.interactSignal.add(handleInteraction);
    }

    function initSceneRenderMethods():Void {
        compositor = new Compositor();

        sdfFontMethod = new SDFFontMethod();
        hitboxMethod = new HitboxMethod();
        presentationMethod = sdfFontMethod;

        var window = Application.current.window;
        this.width = window.width;
        this.height = window.height;
        activate();
    }

    function renderMouse():Void {
        drawFrame(hitboxMethod, mouseSystem.renderTargetTexture.renderTarget);
    }

    function drawFrame(method:SceneRenderMethod, renderTarget:RenderTarget):Void {
        if (glSys.connected) {
            method.start(renderTarget);
            for (scene in scenes) method.drawScene(scene);
            method.end();
        }
    }

    function setSize(width:Int, height:Int):Void {
        this.width = width;
        this.height = height;
        for (scene in scenes) scene.resize(width, height);
        mouseSystem.setSize(width, height);
        compositor.setSize(width, height);
    }

    function activate():Void {
        if (active) return;
        active = true;
        setSize(width, height);
        regulateUserInput();
    }

    function deactivate():Void {
        if (!active) return;
        active = false;
        regulateUserInput();
    }

    function regulateUserInput():Void {
        keyboardSystem.active = active && glSys.connected;
        mouseSystem.active = active && glSys.connected;
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
            glSys.disconnect();
            haxe.Timer.delay(glSys.connect, mils);
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
            case KEYBOARD(type, code, modifier):
                switch (code) {
                    case SPACE: presentationMethod = (modifier.ctrlKey && type != KEY_UP) ? hitboxMethod : sdfFontMethod;
                    case D: if (modifier.ctrlKey && type == KEY_UP) testDisconnect(1000);
                    case _:
                }
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

    #if debug_graphics inline function get_debugGraphics() return compositor.debugGraphics; #end
}
