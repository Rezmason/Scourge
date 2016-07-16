package net.rezmason.hypertype.core;

import net.rezmason.utils.Zig;

class Scene {
    public var valid(default, null):Bool;
    public var camera(default, null):Camera;
    public var bodies(get, null):Iterator<Body>;
    public var focus(default, set):Body;
    public var root(default, null):Body;
    public var stageWidth(default, null):Int;
    public var stageHeight(default, null):Int;

    public var invalidatedSignal(default, null):Zig<Void->Void>;
    public var invalidateHitboxesSignal(default, null):Zig<Void->Void>;
    public var resizeSignal(default, null):Zig<Void->Void>;
    
    var bodiesByID:Map<Int, Body>;

    public function new():Void {
        invalidatedSignal = new Zig();
        invalidateHitboxesSignal = new Zig();
        resizeSignal = new Zig();
        camera = new Camera();
        root = new Body();
        root.setScene(this);
        valid = false;
    }
    
    public inline function resize(stageWidth:Int, stageHeight:Int):Void {
        this.stageWidth = stageWidth;
        this.stageHeight = stageHeight;
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
}
