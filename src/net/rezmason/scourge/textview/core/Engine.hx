package net.rezmason.scourge.textview.core;

import flash.display.Stage;

import haxe.Timer;

import net.rezmason.gl.OutputBuffer;
import net.rezmason.gl.utils.UtilitySet;
import net.rezmason.scourge.textview.core.Interaction;
import net.rezmason.scourge.textview.rendermethods.*;
import net.rezmason.utils.FlatFont;

using Lambda;

class Engine {

    var active:Bool;
    var stage:Stage;
    public var framerate(default, set):Float;
    public var width(default, null):Int;
    public var height(default, null):Int;
    public var ready(default, null):Bool;
    public var invalidateMouse(get, null):Void->Void;

    var updateTimer:Timer;
    var lastTimeStamp:Float;

    var utils:UtilitySet;
    var bodies:Array<Body>;
    var holes:Array<Int>;
    var fontTextures:Map<String, GlyphTexture>;

    var mouseSystem:MouseSystem;
    var keyboardSystem:KeyboardSystem;
    var mouseDownTarget:Body;
    var mouseMethod:RenderMethod;
    var prettyMethod:RenderMethod;
    var mainOutputBuffer:OutputBuffer;

    var onReady:Void->Void;

    public function new(utils:UtilitySet, stage:Stage, fontTextures:Map<String, GlyphTexture>):Void {
        active = false;
        ready = false;
        this.utils = utils;
        this.stage = stage;
        this.fontTextures = fontTextures;

        width = 1;
        height = 1;
        framerate = 1000 / 30;
        bodies = [];
        holes = [];
    }

    public function init(onReady:Void->Void):Void {
        if (ready) {
            onReady();
        } else {
            this.onReady = onReady;

            prettyMethod = new PrettyMethod();
            mouseMethod = new MouseMethod();

            prettyMethod.load(utils.programUtil, onMethodLoaded);
            mouseMethod.load(utils.programUtil, onMethodLoaded);
        }
    }

    public function set_framerate(f:Float):Float return framerate = (f >= 0 ? f : 0);

    public inline function get_invalidateMouse():Void->Void return mouseSystem.invalidate;

    public function addBody(body:Body):Void {
        if (!bodies.has(body)) {
            var hole:Int = holes.length > 0 ? holes.pop() : bodies.length;
            body.setID(hole);
            bodies[hole] = body;
        }
    }

    public function removeBody(body:Body):Void {
        if (bodies[body.id] == body) {
            holes.push(body.id);
            bodies[body.id] = null;
        }
    }

    function onMethodLoaded():Void if (prettyMethod.program != null && mouseMethod.program != null) initScene();

    function initScene():Void {
        mouseSystem = new MouseSystem(utils.drawUtil, stage, renderMouse);
        keyboardSystem = new KeyboardSystem(stage);

        mouseSystem.interact.add(handleInteraction);
        keyboardSystem.interact.add(handleInteraction);

        mouseDownTarget = null;
        // stage.addChild(mouseSystem.view);
        mainOutputBuffer = utils.drawUtil.getMainOutputBuffer();
        addListeners();

        ready = true;
        if (onReady != null) onReady();
        onReady = null;
    }

    function addListeners():Void {
        utils.drawUtil.addRenderCall(onRender);
        // mouseSystem.view.addEventListener(MouseEvent.CLICK, onMouseViewClick);
    }

    function onRender(width:Int, height:Int):Void {
        if (active) render(prettyMethod, mainOutputBuffer);
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

        utils.drawUtil.setOutputBuffer(outputBuffer);
        utils.drawUtil.clear(method.backgroundColor);

        for (body in bodies) {
            if (body.numGlyphs == 0) continue;
            method.setMatrices(body.camera, body.transform);
            method.setGlyphTexture(body.glyphTexture, body.glyphTransform);

            for (segment in body.segments) {
                method.setSegment(segment);
                utils.drawUtil.drawTriangles(segment.indexBuffer, 0, segment.numGlyphs * Almanac.TRIANGLES_PER_GLYPH);
            }
        }

        method.setSegment(null);
        method.deactivate();
        utils.drawUtil.finishOutputBuffer(outputBuffer);
    }

    public function setSize(width:Int, height:Int):Void {
        this.width = width;
        this.height = height;
        for (body in bodies) body.adjustLayout(width, height);
        mouseSystem.setSize(width, height);
        mainOutputBuffer.resize(width, height);
    }

    public function activate():Void {
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
        if (!active) return;
        active = false;
        updateTimer.stop();
        updateTimer = null;
        keyboardSystem.detach();
    }

    public function setKeyboardFocus(body:Body):Void {
        if (bodies.has(body)) keyboardSystem.focusBodyID = body.id;
    }

    public function eachBody():Iterator<Body> return bodies.iterator();

    function onTimer():Void {
        var timeStamp:Float = Timer.stamp();
        var delta:Float = timeStamp - lastTimeStamp;
        for (body in bodies) body.update(delta);
        lastTimeStamp = timeStamp;
    }

    // function onMouseViewClick(?event:Event):Void mouseSystem.invalidate();

    function handleInteraction(source:InteractionSource, interaction:Interaction):Void {

        var bodyID:Int = source.bodyID;
        var glyphID:Int = source.glyphID;
        var target:Body = null;

        if (bodyID >= 0 && bodyID < bodies.length) target = bodies[bodyID];

        switch (interaction) {
            case MOUSE(type, oX, oY):
                if (target == null) {

                    if (type == DROP && mouseDownTarget != null) {
                        target = mouseDownTarget;
                        mouseDownTarget = null;
                    } else {
                        for (body in bodies) {
                            if (!body.catchMouseInRect) continue;
                            if (body.viewRect.contains(oX / stage.stageWidth, oY / stage.stageHeight)) {
                                glyphID = -1;
                                bodyID = body.id;
                                target = body;
                                if (type == MOUSE_DOWN) mouseDownTarget = body;
                                break;
                            }
                        }
                    }
                }

                if (type == CLICK) keyboardSystem.focusBodyID = bodyID;

                if (target != null) {
                    var nX:Float = (oX / stage.stageWidth  - target.viewRect.x) / target.viewRect.width;
                    var nY:Float = (oY / stage.stageHeight - target.viewRect.y) / target.viewRect.height;
                    interaction = MOUSE(type, nX, nY);
                }

                keyboardSystem.attach();

            case _:
        }

        if (target != null) target.receiveInteraction(glyphID, interaction);
    }
}
