package net.rezmason.scourge.textview.ui;

class DragBehavior {
    inline static var SETTLE_FRICTION:Float = 0.925;
    inline static var SETTLE_MIN_SPEED:Float = 0.0001;

    public var dragging(default, null):Bool = false;
    public var settling(default, null):Bool = false;
    public var active(get, null):Bool;
    public var displacement(get, null):Vec3;
    
    var pos:Vec3;
    var startPos:Vec3;
    var lastPos:Vec3;
    var lastDelta:Float;
    var settleVel:Vec3;
    var settlingFunction:Vec3->Vec3;

    public inline function new(settlingFunction:Vec3->Vec3 = null) {
        this.settlingFunction = settlingFunction;
    }

    public inline function update(delta:Float) {
        if (dragging) {
            lastPos = pos.copy();
            lastDelta = delta;
        } else if (settling) {
            pos += settleVel * delta;
            if (settlingFunction != null) {
                settleVel = settlingFunction(pos);
            } else {
                settleVel *= delta + SETTLE_FRICTION * (1 - delta);
                settling = Math.abs(settleVel.x) > SETTLE_MIN_SPEED || Math.abs(settleVel.y) > SETTLE_MIN_SPEED;
            }
        }
    }

    public inline function startDrag(x, y) {
        if (!dragging) {
            dragging = true;
            settling = false;
            pos = new Vec3(x, y, 0);
            lastPos = pos.copy();
            startPos = pos.copy();
        }
    }

    public inline function updateDrag(x, y) {
        if (dragging) {
            pos.x = x;
            pos.y = y;
        }
    }

    public inline function stopDrag() {
        if (dragging) {
            dragging = false;
            if (settlingFunction != null) settleVel = settlingFunction(pos);
            else settleVel = (pos - lastPos) / lastDelta;
            settling = settleVel.x != 0 || settleVel.y != 0;
        }
    }

    inline function get_displacement() return pos - startPos;
    public inline function get_active() return dragging || settling;
}
