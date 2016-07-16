package net.rezmason.hypertype.core;

import lime.utils.UInt8Array;
import net.rezmason.gl.RenderTarget;
import net.rezmason.gl.RenderTargetTexture;
import net.rezmason.hypertype.core.Interaction;
import net.rezmason.utils.Zig;

typedef Hit = { bodyID:Null<Int>, glyphID:Null<Int> };

class MouseSystem {

    static var NULL_HIT:Hit = {bodyID:null, glyphID:null};

    public var renderTarget(default, null):RenderTarget;
    public var invalid(default, null):Bool;
    public var interactSignal(default, null):Zig<Null<Int>->Null<Int>->Interaction->Void>;
    public var refreshSignal(default, null):Zig<Void->Void>;
    var rtt:RenderTargetTexture;
    var data:UInt8Array;
    var lastFocusRegionID:Null<Int>;
    var lastX:Float;
    var lastY:Float;
    
    var hoverHit:Hit;
    var pressHit:Hit;
    var width:Int;
    var height:Int;
    var initialized:Bool;

    public function new():Void {
        interactSignal = new Zig();
        refreshSignal = new Zig();
        lastFocusRegionID = null;
        lastX = Math.NaN;
        lastY = Math.NaN;
        hoverHit = NULL_HIT;
        pressHit = NULL_HIT;
        width = 0;
        height = 0;
        initialized = false;
        rtt = new RenderTargetTexture(UNSIGNED_BYTE);
        renderTarget = rtt.renderTarget;
        invalidate();
    }

    public function setSize(width:Int, height:Int):Void {
        if (!initialized || this.width != width || this.height != height) {
            initialized = true;
            this.width = width;
            this.height = height;
            data = null;
            invalidate();
        }
    }

    public function invalidate():Void invalid = true;

    public function receiveMouseMove(x:Float, y:Float):Void {
        if (!initialized) return;
        if (invalid) refresh();

        var hit:Hit = getHit(x, y);
        if (hitsEqual(hit, hoverHit)) {
            sendInteraction(hit, x, y, MOVE);
        } else {
            sendInteraction(hoverHit, x, y, EXIT);
            hoverHit = hit;
            sendInteraction(hoverHit, x, y, ENTER);
        }

        lastX = x;
        lastY = y;
    }
    
    public function receiveMouseDown(x:Float, y:Float, button:Int):Void {
        if (!initialized) return;
        if (invalid) refresh();
        pressHit = getHit(x, y);
        lastX = x;
        lastY = y;
        sendInteraction(pressHit, x, y, MOUSE_DOWN);
    }

    public function receiveMouseUp(x:Float, y:Float, button:Int):Void {
        if (!initialized) return;
        if (invalid) refresh();
        var hit:Hit = getHit(x, y);
        lastX = x;
        lastY = y;
        sendInteraction(hit, x, y, MOUSE_UP);
        sendInteraction(pressHit, x, y, hitsEqual(hit, pressHit) ? CLICK : DROP);
        pressHit = NULL_HIT;
    }

    function getHit(x:Float, y:Float):Hit {
        if (data == null) return NULL_HIT;
        x = Math.max(0, Math.min(width  - 1, x));
        y = Math.max(0, Math.min(height - 1, y));

        var rectLeft:Int = Std.int(x);
        var rectTop:Int = Std.int(height - 1 - y);
        var rawID:Int = getRawIDFromCoord(rectLeft, rectTop);
        var bodyID:Null<Int> = null;
        var glyphID:Null<Int> = null;

        if (rawID == 0xFFFFFF) {
            // TODO: broad interaction regions
        } else {
            lastFocusRegionID = null;
            bodyID = rawID >> 16 & 0xFF;
            glyphID = rawID & 0xFFFF;
        }

        return {bodyID:bodyID, glyphID:glyphID};
    }

    inline function getRawIDFromCoord(x:Int, y:Int):Int {
        var index = (y * width + x) * 4;
        return (data[index] << 16) | (data[index + 1] << 8) | (data[index + 2] << 0);
    }

    inline function sendInteraction(hit:Hit, x:Float, y:Float, type:MouseInteractionType):Void {
        if (hit.bodyID != null) interactSignal.dispatch(hit.bodyID, hit.glyphID, MOUSE(type, x / width, y / height));
    }

    inline function refresh() {
        rtt.resize(width, height);
        if (data == null) data = new UInt8Array(width * height * 4);
        refreshSignal.dispatch();
        rtt.readBack(data);
        invalid = false;
    }

    inline function hitsEqual(h1:Hit, h2:Hit):Bool {
        var val:Bool = false;
        if (h1 == null && h2 == null) val = true;
        else if (h1 != null && h2 != null) val = h1.bodyID == h2.bodyID && h1.glyphID == h2.glyphID;
        return val;
    }

}
