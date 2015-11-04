package net.rezmason.scourge.textview.ui;

class DragBehavior {
    inline static var POST_DRAG_FRICTION:Float = 0.925;
    inline static var POST_DRAG_MIN_VELOCITY:Float = 0.0001;

    public var dragging(default, null):Bool = false;
    public var postDragging(default, null):Bool = false;
    public var active(get, null):Bool;
    public var dx(get, null):Float = 0;
    public var dy(get, null):Float = 0;
    
    var x:Float = 0;
    var y:Float = 0;
    var startX:Float = 0;
    var startY:Float = 0;
    var lastX:Float = 0;
    var lastY:Float = 0;
    var lastDelta:Float = 0;
    var postVX:Float = 0;
    var postVY:Float = 0;

    public inline function new() {}

    public inline function update(delta:Float) {
        if (dragging) {
            lastX = x;
            lastY = y;
            lastDelta = delta;
        } else if (postDragging) {
            x += postVX * delta;
            y += postVY * delta;
            postDragging = Math.abs(postVX) > POST_DRAG_MIN_VELOCITY || Math.abs(postVY) > POST_DRAG_MIN_VELOCITY;
            postVX *= delta + POST_DRAG_FRICTION * (1 - delta);
            postVY *= delta + POST_DRAG_FRICTION * (1 - delta);
        }
    }

    public inline function startDrag(x, y) {
        if (!dragging) {
            dragging = true;
            postDragging = false;
            this.x = x;
            this.y = y;
            lastX = x;
            lastY = y;
            startX = x;
            startY = y;
        }
    }

    public inline function updateDrag(x, y) {
        if (dragging) {
            this.x = x;
            this.y = y;
        }
    }

    public inline function stopDrag() {
        if (dragging) {
            dragging = false;
            postVX = (x - lastX) / lastDelta;
            postVY = (y - lastY) / lastDelta;
            postDragging = postVX != 0 || postVY != 0;
        }
    }

    public inline function get_dx() return x - startX;
    public inline function get_dy() return y - startY;
    public inline function get_active() return dragging || postDragging;
}
