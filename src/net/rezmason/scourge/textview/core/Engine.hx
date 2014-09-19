package net.rezmason.scourge.textview.core;

import flash.geom.Rectangle;

import haxe.Timer;

import net.rezmason.gl.OutputBuffer;
import net.rezmason.gl.GLFlowControl;
import net.rezmason.gl.GLSystem;
import net.rezmason.scourge.textview.core.Interaction;
import net.rezmason.scourge.textview.core.rendermethods.*;
import net.rezmason.utils.display.FlatFont;
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
    
    var mouseSystem:MouseSystem;
    var keyboardSystem:KeyboardSystem;
    var mouseDownTarget:Body;
    var mouseMethod:RenderMethod;
    var prettyMethod:RenderMethod;
    var viewportOutputBuffer:OutputBuffer;

    public function new(glFlow:GLFlowControl):Void {
        this.glFlow = glFlow;
        active = false;
        ready = false;
        readySignal = new Zig<Void->Void>();
        glSys = new Present(GLSystem);
        
        width = 1;
        height = 1;
        framerate = 1000 / 30;
        bodiesByID = new Map();
    }

    public function init():Void {
        if (ready) {
            readySignal.dispatch();
        } else {
            prettyMethod = new PrettyMethod();
            mouseMethod = new MouseMethod();

            prettyMethod.loadedSignal.add(onMethodLoaded);
            mouseMethod.loadedSignal.add(onMethodLoaded);

            prettyMethod.load();
            mouseMethod.load();
        }
    }

    public function set_framerate(f:Float):Float return framerate = (f >= 0 ? f : 0);

    public function addBody(body:Body):Void {
        readyCheck();
        if (bodiesByID[body.id] == null) {
            bodiesByID[body.id] = body;
            body.redrawHitSignal.add(updateMouseSystem);
            body.adjustLayout(width, height);
        }
    }

    public function removeBody(body:Body):Void {
        readyCheck();
        if (bodiesByID[body.id] == body) {
            bodiesByID.remove(body.id);
            body.redrawHitSignal.remove(updateMouseSystem);
        }
    }

    function onMethodLoaded():Void if (prettyMethod.programLoaded && mouseMethod.programLoaded) initScene();

    function initScene():Void {
        mouseSystem = new MouseSystem();
        mouseSystem.updateSignal.add(renderMouse);
        keyboardSystem = new KeyboardSystem();

        mouseSystem.interact.add(handleInteraction);
        keyboardSystem.interact.add(handleInteraction);

        mouseDownTarget = null;
        viewportOutputBuffer = glSys.viewportOutputBuffer;
        addListeners();

        if (!ready) {
            ready = true;
            readySignal.dispatch();
        }
    }

    function addListeners():Void {
        glFlow.onRender = onRender;
        // mouseSystem.view.addEventListener(MouseEvent.CLICK, onMouseViewClick);
    }

    function onRender(width:Int, height:Int):Void {
        if (active) render(prettyMethod, viewportOutputBuffer);
    }

    function renderMouse():Void {
        render(mouseMethod, mouseSystem.outputBuffer);
    }

    function render(method:RenderMethod, outputBuffer:OutputBuffer):Void {

        if (method == null) {
            trace('Null method.');
            return;
        }

        method.activate();

        glSys.start(outputBuffer);
        glSys.clear(method.backgroundColor);

        for (body in bodiesByID) {
            if (body.numGlyphs == 0) continue;
            method.setMatrices(body.camera, body.transform);
            method.setGlyphTexture(body.glyphTexture, body.glyphTransform);

            for (segment in body.segments) {
                method.setSegment(segment);
                glSys.draw(segment.indexBuffer, 0, segment.numGlyphs * Almanac.TRIANGLES_PER_GLYPH);
            }
        }

        method.setSegment(null);
        method.deactivate();
        glSys.finish();
    }

    public function setSize(width:Int, height:Int):Void {
        readyCheck();
        this.width = width;
        this.height = height;
        for (body in bodiesByID) body.adjustLayout(width, height);
        mouseSystem.setSize(width, height);
        viewportOutputBuffer.resize(width, height);
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
        keyboardSystem.attach();
    }

    public function deactivate():Void {
        readyCheck();
        if (!active) return;
        active = false;
        updateTimer.stop();
        updateTimer = null;
        keyboardSystem.detach();
    }

    public function setKeyboardFocus(body:Body):Void {
        readyCheck();
        if (bodiesByID[body.id] == body) keyboardSystem.focusBodyID = body.id;
    }

    public function eachBody():Iterator<Body> return bodiesByID.iterator();

    function onTimer():Void {
        var timeStamp:Float = Timer.stamp();
        var delta:Float = timeStamp - lastTimeStamp;
        for (body in bodiesByID) body.update(delta);
        lastTimeStamp = timeStamp;
    }

    function updateMouseSystem():Void {
        var viewRectsByBodyID:Map<Int, Rectangle> = new Map();
        for (body in bodiesByID) if (body.catchMouseInRect) viewRectsByBodyID[body.id] = body.viewRect;
        mouseSystem.setRectRegions(viewRectsByBodyID);
        mouseSystem.invalidate();
    }

    // function onMouseViewClick(?event:Event):Void mouseSystem.invalidate();

    function handleInteraction(bodyID:Null<Int>, glyphID:Null<Int>, interaction:Interaction):Void {

        var target:Body = bodiesByID[bodyID];

        switch (interaction) {
            case MOUSE(type, oX, oY):
                if (type == CLICK) keyboardSystem.focusBodyID = bodyID;

                if (target != null) {
                    var rect:Rectangle = target.viewRect;
                    var nX:Float = (oX / width  - rect.x) / rect.width;
                    var nY:Float = (oY / height - rect.y) / rect.height;
                    interaction = MOUSE(type, nX, nY);
                }

                keyboardSystem.attach();

            case _:
        }

        if (target != null) target.receiveInteraction(glyphID, interaction);
    }

    inline function readyCheck():Void if (!ready) throw "Engine hasn't initialized yet.";
}
