package net.rezmason.hypertype.core;

import net.rezmason.utils.Zig;
import lime.math.Rectangle;
using Lambda;

class SceneGraph {

    var invalid:Bool = false;
    var bodiesByID:Map<Int, Body> = new Map();
    public var scene(default, null):Scene;
    var keyboardFocusBodyID:Null<Int> = null;
    public var width(default, null):Int = 1;
    public var height(default, null):Int = 1;
    public var rectsByBodyID(default, null):Map<Int, Rectangle> = new Map();
    public var teaseHitboxesSignal(default, null):Zig<Bool->Void> = new Zig();
    public var toggleConsoleSignal(default, null):Zig<Void->Void> = new Zig();
    public var invalidateHitboxesSignal(default, null):Zig<Void->Void> = new Zig();

    public function new() {
        scene = new Scene();
        scene.invalidateHitboxesSignal.add(invalidateHitboxesSignal.dispatch);
        scene.invalidatedSignal.add(invalidateScene);
        scene.resize(width, height);
        invalidateScene();
    }

    public function setKeyboardFocus(body:Body):Void {
        fetchBodies();
        if (body == null) keyboardFocusBodyID = null;
        else if (bodiesByID[body.id] == body) keyboardFocusBodyID = body.id;
    }

    public function update(delta) {
        fetchBodies();
        for (body in bodiesByID) body.update(delta);
    }

    public function setSize(width:Int, height:Int):Void {
        this.width = width;
        this.height = height;
        scene.resize(width, height);
    }

    public function routeInteraction(bodyID:Null<Int>, glyphID:Null<Int>, interaction:Interaction):Void {
        fetchBodies();
        var target = null;
        switch (interaction) {
            case MOUSE(type, x, y):
                target = bodiesByID[bodyID];
                if (type == CLICK) keyboardFocusBodyID = bodyID;
                if (target != null) {
                    var camera = scene.camera;
                    var rect = camera.rect;
                    var nX = ((x - rect.x) / rect.width ) / camera.scaleX;
                    var nY = ((y - rect.y) / rect.height) / camera.scaleY;
                    interaction = MOUSE(type, nX, nY);
                }
            case KEYBOARD(type, code, modifier):
                target = bodiesByID[keyboardFocusBodyID];
                switch (code) {
                    case SPACE: teaseHitboxesSignal.dispatch(modifier.ctrlKey && type != KEY_UP);
                    case GRAVE: if (type == KEY_DOWN) toggleConsoleSignal.dispatch();
                    case _:
                }
        }
        if (target != null) target.interactionSignal.dispatch(glyphID, interaction);
    }

    inline function invalidateScene() invalid = true;

    inline function fetchBodies(broadcast = true):Void {
        if (invalid) {
            invalid = false;
            for (bodyID in bodiesByID.keys()) bodiesByID.remove(bodyID);
            for (body in scene.bodies) bodiesByID[body.id] = body;
        }
    }
}
