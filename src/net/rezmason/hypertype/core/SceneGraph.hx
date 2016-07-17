package net.rezmason.hypertype.core;

import lime.math.Vector4;
import net.rezmason.utils.Zig;
using Lambda;

class SceneGraph {

    var bodiesByID:Map<Int, Body>;
    var keyboardFocusBody:Body = null;
    var width:Int = 1;
    var height:Int = 1;
    public var aspectRatio(default, null):Float = 1;
    public var camera(default, null):Camera = new Camera();
    public var root(default, null):Body = new Body();
    public var bodies(get, null):Iterator<Body>;
    public var focus(default, set):Body;

    public var teaseHitboxesSignal(default, null):Zig<Bool->Void> = new Zig();
    public var toggleConsoleSignal(default, null):Zig<Void->Void> = new Zig();
    public var invalidateHitboxesSignal(default, null):Zig<Void->Void> = new Zig();
    public var resizeSignal(default, null):Zig<Void->Void> = new Zig();
    @:allow(net.rezmason.hypertype.core) var screenParams(default, null):Vector4 = new Vector4();

    public function new() {
        root.invalidateSignal.add(invalidate);
        screenParams.x = 1;
        setSize(width, height);
    }

    public function setKeyboardFocus(body:Body):Void keyboardFocusBody = body;

    public function update(delta) {
        fetchBodies();
        for (body in bodiesByID) body.update(delta);
    }

    public function setSize(width:Int, height:Int):Void {
        this.width = width;
        this.height = height;
        aspectRatio = width / height;
        screenParams.x = aspectRatio;
        camera.resize(width, height);
        resizeSignal.dispatch();
    }

    public function routeInteraction(bodyID:Null<Int>, glyphID:Null<Int>, interaction:Interaction):Void {
        fetchBodies();
        var target = null;
        switch (interaction) {
            case MOUSE(type, x, y):
                target = bodiesByID[bodyID];
                if (type == CLICK) keyboardFocusBody = target;
                if (target != null) {
                    var rect = camera.rect;
                    var nX = ((x - rect.x) / rect.width ) / camera.scaleX;
                    var nY = ((y - rect.y) / rect.height) / camera.scaleY;
                    interaction = MOUSE(type, nX, nY);
                }
            case KEYBOARD(type, code, modifier):
                target = keyboardFocusBody;
                switch (code) {
                    case SPACE: teaseHitboxesSignal.dispatch(modifier.ctrlKey && type != KEY_UP);
                    case GRAVE: if (type == KEY_DOWN) toggleConsoleSignal.dispatch();
                    case _:
                }
        }
        if (target != null) target.interact(glyphID, interaction);
    }

    public inline function invalidate():Void {
        bodiesByID = null;
        invalidateHitboxesSignal.dispatch();
    }

    inline function fetchBodies():Void {
        if (bodiesByID == null) {
            bodiesByID = [root.id => root];
            mapBodyChildren(root);
        }
    }

    inline function get_bodies():Iterator<Body> {
        fetchBodies();
        return bodiesByID.iterator();
    }

    function mapBodyChildren(base:Body):Void {
        for (body in base.children()) {
            bodiesByID[body.id] = body;
            mapBodyChildren(body);
        }
    }

    inline function set_focus(body:Body):Body {
        fetchBodies();
        focus = (body == null || bodiesByID[body.id] == null) ? null : body;
        return focus;
    }
}
