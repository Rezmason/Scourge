package net.rezmason.hypertype.core;

import lime.math.Vector4;
import net.rezmason.utils.Zig;
using Lambda;

class SceneGraph {

    var bodiesByID:Map<Int, Body>;
    var keyboardFocusBody:Body = null;
    var pixelWidth:UInt = 72;
    var pixelHeight:UInt = 72;
    var pixelsPerInch:UInt = 72;
    public var widthInInches(get, null):Float;
    public var heightInInches(get, null):Float;
    public var aspectRatio(get, null):Float;
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
        setSize(pixelWidth, pixelHeight, pixelsPerInch);
    }

    public function setKeyboardFocus(body:Body):Void keyboardFocusBody = body;

    public function update(delta) {
        fetchBodies();
        for (body in bodiesByID) body.update(delta);
    }

    public function setSize(pixelWidth:UInt, pixelHeight:UInt, pixelsPerInch:UInt):Void {
        this.pixelWidth = pixelWidth;
        this.pixelHeight = pixelHeight;
        this.pixelsPerInch = pixelsPerInch;
        screenParams.x = aspectRatio;
        camera.resize(widthInInches, heightInInches);
        resizeSignal.dispatch();
    }

    public function routeInteraction(bodyID:Null<Int>, glyphID:Null<Int>, interaction:Interaction):Void {
        fetchBodies();
        var target = null;
        switch (interaction) {
            case MOUSE(type, x, y):
                target = bodiesByID[bodyID];
                if (type == CLICK) keyboardFocusBody = target;
                if (target != null) interaction = MOUSE(type, x, y);
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

    function mapBodyChildren(base:Body):Void {
        for (body in base.children()) {
            bodiesByID[body.id] = body;
            mapBodyChildren(body);
        }
    }

    inline function get_bodies():Iterator<Body> {
        fetchBodies();
        return bodiesByID.iterator();
    }

    inline function set_focus(body:Body):Body {
        fetchBodies();
        focus = (body == null || bodiesByID[body.id] == null) ? null : body;
        return focus;
    }

    inline function get_aspectRatio() return pixelWidth / pixelHeight;
    inline function get_widthInInches() return pixelWidth / pixelsPerInch;
    inline function get_heightInInches() return pixelHeight / pixelsPerInch;
}
