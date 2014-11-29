package net.rezmason.scourge.textview.core;

import net.rezmason.utils.Zig;

class Scene {
    public var redrawHitSignal(default, null):Zig<Void->Void>;
    public var bodyAddedSignal(default, null):Zig<Body->Void>;
    public var bodyRemovedSignal(default, null):Zig<Body->Void>;
    public var bodies(get, null):Iterator<Body>;
    public var focus(default, set):Body;

    var bodiesByID:Map<Int, Body>;
    var stageWidth:Int;
    var stageHeight:Int;

    public function new():Void {
        bodiesByID = new Map();
        redrawHitSignal = new Zig();
        bodyAddedSignal = new Zig();
        bodyRemovedSignal = new Zig();
    }

    public function addBody(body:Body):Void {
        bodiesByID[body.id] = body;
        bodyAddedSignal.dispatch(body);
        body.resize(stageWidth, stageHeight);
        body.redrawHitSignal.add(redrawHitSignal.dispatch);
    }

    public function removeBody(body:Body):Void {
        bodiesByID.remove(body.id);
        bodyRemovedSignal.dispatch(body);
        body.redrawHitSignal.remove(redrawHitSignal.dispatch);
        if (focus == body) focus = null;
    }

    public function resize(stageWidth:Int, stageHeight:Int):Void {
        this.stageWidth = stageWidth;
        this.stageHeight = stageHeight;
        for (body in bodiesByID) body.resize(stageWidth, stageHeight);
    }

    inline function get_bodies():Iterator<Body> return bodiesByID.iterator();
    inline function set_focus(body:Body):Body {
        focus = (body == null || bodiesByID[body.id] == null) ? null : body;
        redrawHitSignal.dispatch();
        return focus;
    }
}
