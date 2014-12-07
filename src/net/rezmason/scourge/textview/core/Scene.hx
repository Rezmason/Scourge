package net.rezmason.scourge.textview.core;

import net.rezmason.utils.Zig;

class Scene {
    public var camera(default, null):Camera;
    public var bodies(get, null):Iterator<Body>;
    public var focus(default, set):Body;
    public var stageWidth(default, null):Int;
    public var stageHeight(default, null):Int;

    public var bodyAddedSignal(default, null):Zig<Body->Void>;
    public var bodyRemovedSignal(default, null):Zig<Body->Void>;
    public var redrawHitSignal(default, null):Zig<Void->Void>;
    public var resizeSignal(default, null):Zig<Void->Void>;
    
    var bodiesByID:Map<Int, Body>;

    public function new():Void {
        bodiesByID = new Map();
        bodyAddedSignal = new Zig();
        bodyRemovedSignal = new Zig();
        redrawHitSignal = new Zig();
        resizeSignal = new Zig();
        camera = new Camera();
    }

    public function addBody(body:Body):Void {
        if (body.scene != null && body.scene != this) body.scene.removeBody(body);
        bodiesByID[body.id] = body;
        body.setScene(this);
        bodyAddedSignal.dispatch(body);
    }

    public function removeBody(body:Body):Void {
        bodiesByID.remove(body.id);
        body.setScene(null);
        if (focus == body) focus = null;
        bodyRemovedSignal.dispatch(body);
    }

    public function resize(stageWidth:Int, stageHeight:Int):Void {
        this.stageWidth = stageWidth;
        this.stageHeight = stageHeight;
        camera.resize(stageWidth, stageHeight);
        resizeSignal.dispatch();
    }

    inline function get_bodies():Iterator<Body> return bodiesByID.iterator();
    inline function set_focus(body:Body):Body {
        focus = (body == null || bodiesByID[body.id] == null) ? null : body;
        redrawHitSignal.dispatch();
        return focus;
    }
}
