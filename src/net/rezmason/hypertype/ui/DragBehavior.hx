package net.rezmason.hypertype.ui;

import net.rezmason.math.Vec3;

class DragBehavior {
    inline static var SETTLE_FRICTION:Float = 0.925;
    inline static var SETTLE_MIN_SPEED:Float = 0.0001;

    public var dragging(default, null):Bool = false;
    public var settling(default, null):Bool = false;
    public var active(get, null):Bool;
    public var displacement(get, null):Vec3;
    
    var pos:Vec3 = new Vec3(0, 0, 0);
    var startPos:Vec3 = new Vec3(0, 0, 0);
    var lastPos:Vec3 = new Vec3(0, 0, 0);
    var delta:Float;
    var settleVel:Vec3 = new Vec3(0, 0, 0);

    public function new() {}

    public function update(delta:Float) {
        if (dragging) {
            this.delta += delta;
        } else if (settling) {
            pos += settleVel * delta;
            settleVel *= delta + SETTLE_FRICTION * (1 - delta);
            settling = Math.abs(settleVel.x) > SETTLE_MIN_SPEED || Math.abs(settleVel.y) > SETTLE_MIN_SPEED;
        }
    }

    public function startDrag(x, y) {
        if (!dragging) {
            dragging = true;
            settling = false;
            pos.x = x;
            pos.y = y;
            lastPos.copyFrom(pos);
            startPos.copyFrom(pos);
            delta = 0;
        }
    }

    public function updateDrag(x, y) {
        if (dragging) {
            lastPos.copyFrom(pos);
            pos.x = x;
            pos.y = y;
            delta = 0;
        }
    }

    public function stopDrag() {
        if (dragging) {
            dragging = false;
            if (delta != 0) {
                settleVel = (pos - lastPos) / delta;
            } else {
                settleVel.x = 0;
                settleVel.y = 0;
            }
            settling = settleVel.x != 0 || settleVel.y != 0;
        }
    }

    function get_displacement() return pos - startPos;
    public function get_active() return dragging || settling;
}
