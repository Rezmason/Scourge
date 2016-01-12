package net.rezmason.hypertype.core;

import net.rezmason.utils.Zig;
import lime.math.Rectangle;
using Lambda;

class SceneGraph {

    var invalid:Bool = false;
    var bodiesByID:Map<Int, Body> = new Map();
    var scenes:Array<Scene> = [];
    var keyboardFocusBodyID:Null<Int> = null;
    public var width(default, null):Int = 1;
    public var height(default, null):Int = 1;
    public var rectsByBodyID(default, null):Map<Int, Rectangle> = new Map();
    public var teaseHitboxesSignal(default, null):Zig<Bool->Void> = new Zig();
    public var updateRectsSignal(default, null):Zig<Map<Int, Rectangle>->Void> = new Zig();

    public function new() {}

    public function addScene(scene:Scene):Void {
        if (!scenes.has(scene)) {
            scenes.push(scene);
            scene.redrawHitSignal.add(updateRects);
            scene.invalidatedSignal.add(invalidateScene);
            scene.resize(width, height);
            invalidateScene();
            updateRects();
        }
    }

    public function removeScene(scene:Scene):Void {
        if (scenes.has(scene)) {
            scenes.remove(scene);
            scene.redrawHitSignal.remove(updateRects);
            scene.invalidatedSignal.remove(invalidateScene);
            invalidateScene();
            updateRects();
        }
    }

    public function eachScene():Iterator<Scene> return scenes.iterator();

    public function setKeyboardFocus(body:Body):Void {
        fetchBodies();
        if (bodiesByID[body.id] == body) keyboardFocusBodyID = body.id;
    }

    public function update(delta) {
        fetchBodies();
        for (body in bodiesByID) body.update(delta);
    }

    public function setSize(width:Int, height:Int):Void {
        this.width = width;
        this.height = height;
        for (scene in scenes) scene.resize(width, height);
    }

    function updateRects():Void {
        fetchBodies();
        for (key in rectsByBodyID.keys()) rectsByBodyID.remove(key);
        for (scene in scenes) if (scene.focus != null) rectsByBodyID[scene.focus.id] = scene.camera.rect;
        updateRectsSignal.dispatch(rectsByBodyID);
    }

    public function routeInteraction(bodyID:Null<Int>, glyphID:Null<Int>, interaction:Interaction):Void {
        fetchBodies();
        var target = null;
        switch (interaction) {
            case MOUSE(type, oX, oY):
                target = bodiesByID[bodyID];
                if (type == CLICK) keyboardFocusBodyID = bodyID;
                if (target != null) {
                    var camera = target.scene.camera;
                    var rect = camera.rect;
                    var nX = ((oX / width  - rect.x) / rect.width ) / camera.scaleX;
                    var nY = ((oY / height - rect.y) / rect.height) / camera.scaleY;
                    interaction = MOUSE(type, nX, nY);
                }
            case KEYBOARD(type, code, modifier):
                target = bodiesByID[keyboardFocusBodyID];
                switch (code) {
                    case SPACE: teaseHitboxesSignal.dispatch(modifier.ctrlKey && type != KEY_UP);
                    case _:
                }
        }
        if (target != null) target.interactionSignal.dispatch(glyphID, interaction);
    }

    inline function invalidateScene() invalid = true;

    inline function fetchBodies():Void {
        if (invalid) {
            invalid = false;
            for (bodyID in bodiesByID.keys()) bodiesByID.remove(bodyID);
            for (scene in scenes) for (body in scene.bodies) bodiesByID[body.id] = body;
        }
    }
}
