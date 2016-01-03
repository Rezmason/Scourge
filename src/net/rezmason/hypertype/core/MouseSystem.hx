package net.rezmason.hypertype.core;

import net.rezmason.gl.GLTypes;

import net.rezmason.gl.GLSystem;
import net.rezmason.gl.TextureRenderTarget;
import net.rezmason.gl.GLTypes;
import net.rezmason.utils.Zig;
import net.rezmason.utils.santa.Present;

import net.rezmason.hypertype.core.Interaction;

typedef Hit = {
    var bodyID:Null<Int>;
    var glyphID:Null<Int>;
}

typedef ReadbackData = #if ogl lime.utils.UInt8Array #end ;

class MouseSystem {

    static var NULL_HIT:Hit = {bodyID:null, glyphID:null};

    public var active(default, set):Bool;
    public var renderTarget(default, null):TextureRenderTarget;
    public var invalid(default, null):Bool;
    public var interactSignal(default, null):Zig<Null<Int>->Null<Int>->Interaction->Void>;
    public var refreshSignal(default, null):Zig<Void->Void>;
    var data:ReadbackData;
    var rectRegionsByID:Map<Int, Rectangle>;
    var lastRectRegionID:Null<Int>;
    var lastX:Float;
    var lastY:Float;
    
    var hoverHit:Hit;
    var pressHit:Hit;
    var width:Int;
    var height:Int;
    var initialized:Bool;
    var glSys:GLSystem;

    public function new():Void {
        active = false;
        interactSignal = new Zig();
        glSys = new Present(GLSystem);
        refreshSignal = new Zig();
        rectRegionsByID = null;
        lastRectRegionID = null;
        lastX = Math.NaN;
        lastY = Math.NaN;

        hoverHit = NULL_HIT;
        pressHit = NULL_HIT;

        width = 0;
        height = 0;
        initialized = false;
        invalidate();

        renderTarget = glSys.createTextureRenderTarget(UNSIGNED_BYTE);
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

    public function setRectRegions(rectRegionsByID:Map<Int, Rectangle>):Void {
        this.rectRegionsByID = rectRegionsByID;
        if (lastRectRegionID != null && rectRegionsByID[lastRectRegionID] == null) {
            lastRectRegionID = null;
            onMouseMove(lastX, lastY);
        }
    }

    public function invalidate():Void invalid = true;

    public function onMouseMove(x:Float, y:Float):Void {
        if (!initialized || !active) return;
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
    
    public function onMouseDown(x:Float, y:Float, button:Int):Void {
        if (!initialized || !active) return;
        if (invalid) refresh();
        pressHit = getHit(x, y);
        lastX = x;
        lastY = y;
        sendInteraction(pressHit, x, y, MOUSE_DOWN);
    }

    public function onMouseUp(x:Float, y:Float, button:Int):Void {
        if (!initialized || !active) return;
        if (invalid) refresh();
        var hit:Hit = getHit(x, y);
        lastX = x;
        lastY = y;
        sendInteraction(hit, x, y, MOUSE_UP);
        sendInteraction(pressHit, x, y, hitsEqual(hit, pressHit) ? CLICK : DROP);
        pressHit = NULL_HIT;
    }

    inline function set_active(val:Bool):Bool {
        if (active != val) {
            active = val;
            if (active) invalidate();
        }
        return val;
    }

    function getHit(x:Float, y:Float):Hit {

        if (data == null) return NULL_HIT;

        if (x < 0) x = 0;
        if (x >= width) x = width - 1;

        if (y < 0) y = 0;
        if (y >= height) y = height - 1;

        var rectLeft:Int = Std.int(x);
        var rectTop:Int = Std.int(#if ogl height - 1 - #end y);
        
        var rawID:Int = getRawIDFromCoord(rectLeft, rectTop);
        var bodyID:Null<Int> = null;
        var glyphID:Null<Int> = null;

        if (rawID == 0xFFFFFF) {
            if (rectRegionsByID != null) {
                if (lastRectRegionID != null && rectRegionsByID[lastRectRegionID].contains(x / width, y / height)) {
                    bodyID = lastRectRegionID;
                } else {
                    for (id in rectRegionsByID.keys()) {
                        if (rectRegionsByID[id].contains(x / width, y / height)) {
                            bodyID = id;
                            break;
                        }
                    }
                }
            }
            lastRectRegionID = bodyID;
        } else {
            lastRectRegionID = null;
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
        if (hit.bodyID != null) interactSignal.dispatch(hit.bodyID, hit.glyphID, MOUSE(type, x, y));
    }

    inline function refresh() {
        renderTarget.resize(width, height);
        if (data == null) data = cast glSys.createReadbackData(width, height, UNSIGNED_BYTE);
        refreshSignal.dispatch();
        renderTarget.readBack(data);
        invalid = false;
    }

    inline function hitsEqual(h1:Hit, h2:Hit):Bool {
        var val:Bool = false;
        if (h1 == null && h2 == null) val = true;
        else if (h1 != null && h2 != null) val = h1.bodyID == h2.bodyID && h1.glyphID == h2.glyphID;
        return val;
    }

}
