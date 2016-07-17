package net.rezmason.hypertype.core;

import lime.math.Rectangle;
import lime.math.Vector4;
import net.rezmason.utils.Zig;
using Lambda;

class SceneGraph {

    var invalid:Bool = false;
    var keyboardFocusBodyID:Null<Int> = null;
    public var width(default, null):Int = 1;
    public var height(default, null):Int = 1;
    public var rectsByBodyID(default, null):Map<Int, Rectangle> = new Map();
    public var teaseHitboxesSignal(default, null):Zig<Bool->Void> = new Zig();
    public var toggleConsoleSignal(default, null):Zig<Void->Void> = new Zig();
    public var valid(default, null):Bool;
    public var camera(default, null):Camera;
    public var bodies(get, null):Iterator<Body>;
    public var focus(default, set):Body;
    public var root(default, null):Body;
    public var stageWidth(default, null):Int;
    public var stageHeight(default, null):Int;
    public var apsectRatio(get, null):Float;

    public var invalidatedSignal(default, null):Zig<Void->Void>;
    public var invalidateHitboxesSignal(default, null):Zig<Void->Void>;
    public var resizeSignal(default, null):Zig<Void->Void>;
    @:allow(net.rezmason.hypertype.core) var screenParams(default, null):Vector4;
    
    var bodiesByID:Map<Int, Body>;

    public function new() {
        invalidatedSignal = new Zig();
        invalidateHitboxesSignal = new Zig();
        resizeSignal = new Zig();
        camera = new Camera();
        root = new Body();
        root.setScene(this);
        screenParams = new Vector4();
        screenParams.x = 1;
        valid = false;
        invalidatedSignal.add(invalidateScene);
        resize(width, height);
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
        resize(width, height);
    }

    public function routeInteraction(bodyID:Null<Int>, glyphID:Null<Int>, interaction:Interaction):Void {
        fetchBodies();
        var target = null;
        switch (interaction) {
            case MOUSE(type, x, y):
                target = bodiesByID[bodyID];
                if (type == CLICK) keyboardFocusBodyID = bodyID;
                if (target != null) {
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

    public inline function resize(stageWidth:Int, stageHeight:Int):Void {
        this.stageWidth = stageWidth;
        this.stageHeight = stageHeight;
        screenParams.x = stageWidth / stageHeight;
        camera.resize(stageWidth, stageHeight);
        resizeSignal.dispatch();
    }

    public inline function invalidate():Void {
        bodiesByID = null;
        invalidatedSignal.dispatch();
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

    inline function get_apsectRatio() return stageWidth / stageHeight;

    inline function invalidateScene() invalid = true;
}
