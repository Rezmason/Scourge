package net.rezmason.scourge.textview.core;

import flash.geom.Rectangle;

import haxe.Timer;

import net.rezmason.gl.OutputBuffer;
import net.rezmason.gl.GLFlowControl;
import net.rezmason.gl.GLSystem;
import net.rezmason.scourge.textview.core.rendermethods.*;
import net.rezmason.utils.Zig;
import net.rezmason.utils.santa.Present;

using Lambda;

class Engine {

    var active:Bool;
    public var framerate(default, set):Float;
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
    
    var mouseSystem:MouseSystem;
    var keyboardSystem:KeyboardSystem;
    var mouseDownTarget:Body;
    var mouseMethod:RenderMethod;
    var prettyMethod:RenderMethod;

    public function new(glFlow:GLFlowControl):Void {
        this.glFlow = glFlow;
        active = false;
        ready = false;
        readySignal = new Zig();
        glSys = new Present(GLSystem);
        
        width = 1;
        height = 1;
        framerate = 1000 / 30;
        bodiesByID = new Map();
        scenes = [];
    }

    public function init():Void {
        if (ready) {
            readySignal.dispatch();
        } else {
            initInteractionSystems();
            initRenderMethods();
            addListeners();
        }
    }

    public function set_framerate(f:Float):Float return framerate = (f >= 0 ? f : 0);

    public function addScene(scene:Scene):Void {
        readyCheck();
        if (!scenes.has(scene)) {
            scenes.push(scene);
            scene.redrawHitSignal.add(updateMouseSystem);
            scene.bodyAddedSignal.add(addBody);
            scene.bodyRemovedSignal.add(removeBody);
            for (body in scene.bodies) addBody(body);
            scene.resize(width, height);
        }
    }

    public function removeScene(scene:Scene):Void {
        readyCheck();
        if (scenes.has(scene)) {
            scenes.remove(scene);
            scene.redrawHitSignal.remove(updateMouseSystem);
            scene.bodyAddedSignal.remove(addBody);
            scene.bodyRemovedSignal.remove(removeBody);
            for (body in scene.bodies) removeBody(body);
        }
    }

    function addBody(body:Body):Void {
        readyCheck();
        bodiesByID[body.id] = body;
    }

    function removeBody(body:Body):Void {
        readyCheck();
        bodiesByID.remove(body.id);
    }

    function initInteractionSystems():Void {
        mouseSystem = new MouseSystem();
        mouseSystem.updateSignal.add(renderMouse);
        keyboardSystem = new KeyboardSystem();

        mouseSystem.interact.add(handleInteraction);
        keyboardSystem.interact.add(handleInteraction);

        mouseDownTarget = null;
    }

    function initRenderMethods():Void {
        prettyMethod = new PrettyMethod();
        mouseMethod = new MouseMethod();

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
        // mouseSystem.view.addEventListener(MouseEvent.CLICK, onMouseViewClick);
    }

    function onRender(width:Int, height:Int):Void {
        if (active) render(prettyMethod, glSys.viewportOutputBuffer);
    }

    function onDisconnect():Void {
        regulateUserInput();
    }

    function onConnect():Void {
        regulateUserInput();
    }

    function renderMouse():Void {
        render(mouseMethod, mouseSystem.outputBuffer);
    }

    function render(method:RenderMethod, outputBuffer:OutputBuffer):Void {
        //trace('rendering with method ${Std.is(method, PrettyMethod) ? "pretty" : "mouse"}');
        if (glSys.connected) {
            if (method == null) {
                trace('Null method.');
            } else {
                method.activate();

                glSys.start(outputBuffer);
                glSys.clear(method.backgroundColor);

                for (scene in scenes) {
                    for (body in scene.bodies) {
                        if (body.numGlyphs == 0) continue;
                        method.setMatrices(body.camera.transform, body.transform);
                        method.setGlyphTexture(body.glyphTexture, body.glyphTransform);

                        for (segment in body.segments) {
                            method.setSegment(segment);
                            glSys.draw(segment.indexBuffer, 0, segment.numGlyphs * Almanac.TRIANGLES_PER_GLYPH);
                        }
                    }
                }

                method.setSegment(null);
                method.deactivate();
                glSys.finish();
            }
        }
    }

    public function setSize(width:Int, height:Int):Void {
        readyCheck();
        this.width = width;
        this.height = height;
        for (body in bodiesByID) body.resize(width, height);
        mouseSystem.setSize(width, height);
        glSys.viewportOutputBuffer.resize(width, height);
    }

    public function activate():Void {
        readyCheck();
        if (active) return;
        active = true;

        updateTimer = new Timer(Std.int(framerate));
        updateTimer.run = onTimer;
        lastTimeStamp = Timer.stamp();
        setSize(width, height);
        onTimer();
        regulateUserInput();
    }

    public function deactivate():Void {
        readyCheck();
        if (!active) return;
        active = false;
        updateTimer.stop();
        updateTimer = null;
        regulateUserInput();
    }

    function regulateUserInput():Void {
        if (active && glSys.connected) {
            keyboardSystem.attach();
            mouseSystem.attach();
        } else {
            keyboardSystem.detach();
            mouseSystem.detach();
        }
    }

    public function setKeyboardFocus(body:Body):Void {
        readyCheck();
        if (bodiesByID[body.id] == body) keyboardSystem.focusBodyID = body.id;
    }

    function onTimer():Void {
        var timeStamp:Float = Timer.stamp();
        var delta:Float = timeStamp - lastTimeStamp;
        for (body in bodiesByID) body.update(delta);
        lastTimeStamp = timeStamp;
    }

    function updateMouseSystem():Void {
        var rectsByBodyID:Map<Int, Rectangle> = new Map();
        for (body in bodiesByID) if (body.catchMouseInRect) rectsByBodyID[body.id] = body.camera.rect;
        mouseSystem.setRectRegions(rectsByBodyID);
        mouseSystem.invalidate();
    }

    function testDisconnect(mils:UInt):Void {
        if (glSys.connected) {
            glFlow.disconnect();
            Timer.delay(glFlow.connect, mils);
        }
    }

    // function onMouseViewClick(?event:Event):Void mouseSystem.invalidate();

    function handleInteraction(bodyID:Null<Int>, glyphID:Null<Int>, interaction:Interaction):Void {

        var target:Body = bodiesByID[bodyID];

        switch (interaction) {
            case MOUSE(type, oX, oY):
                if (type == CLICK) keyboardSystem.focusBodyID = bodyID;

                if (target != null) {
                    var rect:Rectangle = target.camera.rect;
                    var nX:Float = (oX / width  - rect.x) / rect.width;
                    var nY:Float = (oY / height - rect.y) / rect.height;
                    interaction = MOUSE(type, nX, nY);
                }
            case _:
        }

        if (target != null) target.receiveInteraction(glyphID, interaction);
    }

    inline function readyCheck():Void if (!ready) throw "Engine hasn't initialized yet.";
}
