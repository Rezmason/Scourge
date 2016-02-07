package net.rezmason.hypertype.ui;

import net.rezmason.math.Vec3;
import net.rezmason.utils.Zig;

class LoopingDragBehavior extends DragBehavior {
    inline static var SETTLED_DIST_SQUARED:Float = 0.00001;
    inline static var SETTLE_SNAP:Float = 10;

    public var horizontalWrapSignal(default, null):Zig<Int->Void> = new Zig();
    public var verticalWrapSignal(default, null):Zig<Int->Void> = new Zig();

    var southBlocked:Bool = false;
    var northBlocked:Bool = false;
    var westBlocked:Bool = false;
    var eastBlocked:Bool = false;

    var marblePos:Vec3 = new Vec3(0, 0, 0);

    override public function update(delta:Float) {
        settling = !dragging && !isSettled();
        if (settling) {
            marblePos.x *= 1 - SETTLE_SNAP * delta;
            marblePos.y *= 1 - SETTLE_SNAP * delta;
        }
    }

    override public function updateDrag(x, y) {
        if (dragging) {
            super.updateDrag(x, y);
            marblePos.x += pos.x - lastPos.x;
            marblePos.y += pos.y - lastPos.y;
            
            if (southBlocked && marblePos.y < -0.3) marblePos.y = -0.3;
            if (northBlocked && marblePos.y >  0.3) marblePos.y =  0.3;
            if (eastBlocked  && marblePos.x >  0.3) marblePos.x =  0.3;
            if (westBlocked  && marblePos.x < -0.3) marblePos.x = -0.3;
            
            // Wrap marble's position
            var horizontalWrap:Int = Std.int(Math.floor(marblePos.x + 0.5));
            var verticalWrap:Int   = Std.int(Math.floor(marblePos.y + 0.5));
            marblePos.x -= horizontalWrap;
            marblePos.y -= verticalWrap;
            
            // Broadcast wrap events
            if (pos.x - lastPos.x > pos.y - lastPos.y) {
                if (horizontalWrap != 0) horizontalWrapSignal.dispatch(horizontalWrap);
                if (verticalWrap   != 0) verticalWrapSignal.dispatch(verticalWrap);
            } else {
                if (verticalWrap   != 0) verticalWrapSignal.dispatch(verticalWrap);
                if (horizontalWrap != 0) horizontalWrapSignal.dispatch(horizontalWrap);
            }
        }
    }

    override public function stopDrag() {
        dragging = false;
        settling = !isSettled();
    }

    public function setWalls(north, south, east, west) {
        northBlocked = north;
        southBlocked = south;
        eastBlocked = east;
        westBlocked = west;
    }

    function isSettled() return marblePos.x * marblePos.x + marblePos.y * marblePos.y < SETTLED_DIST_SQUARED;
    override function get_displacement() return marblePos;
    override public function get_active() return dragging || settling;
}
