package net.rezmason.scourge.textview.core;

import net.rezmason.gl.GLTypes;

import net.rezmason.gl.GLSystem;
import net.rezmason.gl.ReadbackOutputBuffer;
import net.rezmason.gl.Data;
import net.rezmason.utils.Zig;
import net.rezmason.utils.santa.Present;

import net.rezmason.scourge.textview.core.Interaction;

typedef Hit = {
    var bodyID:Null<Int>;
    var glyphID:Null<Int>;
}

typedef XY = { x:Float, y:Float };

class MouseSystem {

    static var NULL_HIT:Hit = {bodyID:null, glyphID:null};

    public var isAttached(default, null):Bool;
    public var outputBuffer(default, null):ReadbackOutputBuffer;
    public var invalid(default, null):Bool;
    public var interact(default, null):Zig<Null<Int>->Null<Int>->Interaction->Void>;
    public var updateSignal(default, null):Zig<Void->Void>;
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
    var shim:Shim;

    public function new():Void {
        isAttached = false;
        interact = new Zig();
        shim = new Present(Shim);
        glSys = new Present(GLSystem);
        updateSignal = new Zig();
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

        outputBuffer = glSys.createReadbackOutputBuffer();
    }

    public function attach():Void {
        if (!isAttached) {
            isAttached = true;
            shim.mouseMoveSignal.add(onMouseMove);
            shim.mouseDownSignal.add(onMouseDown);
            shim.mouseUpSignal.add(onMouseUp);
            invalidate();
        }
    }

    public function detach():Void {
        if (isAttached) {
            isAttached = false;
            shim.mouseMoveSignal.remove(onMouseMove);
            shim.mouseDownSignal.remove(onMouseDown);
            shim.mouseUpSignal.remove(onMouseUp);
        }
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
        if (rectRegionsByID[lastRectRegionID] == null) {
            lastRectRegionID = null;
            onMouseMove(lastX, lastY);
        }
    }

    public function invalidate():Void invalid = true;

    function getHit(x:Float, y:Float):Hit {

        if (data == null || data.length < cast width * height * 4) return NULL_HIT;

        if (x < 0) x = 0;
        if (x >= width) x = width - 1;

        if (y < 0) y = 0;
        if (y >= height) y = height - 1;

        var rectLeft:Int = Std.int(x);
        var rectTop:Int = Std.int(#if !flash height - 1 - #end y);
        var offset:Int = #if flash 1 #else 0 #end;

        var rawID:Int = getRawIDFromIndex((rectTop * width + rectLeft) * 4 + offset);

        #if flash
            // Ignore any edge pixels. Deals with antialiasing.
            // After all, if a hit area is important, it'll be big, and its edge pixels won't matter.
            for (row in rectTop - 1...rectTop + 2) {
                if (row < 0 || row >= height) continue; // Skip edges
                for (col in rectLeft - 1...rectLeft + 2) {
                    if (col < 0 || col >= width) continue; // Skip edges

                    // Blurry edge test
                    if (getRawIDFromIndex((row * width + col) * 4 + offset) != rawID) return NULL_HIT;
                }
            }
        #end

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

    inline function getRawIDFromIndex(index:Int):Int {
        return (data[index] << 16) | (data[index + 1] << 8) | (data[index + 2] << 0);
    }

    function onMouseMove(x:Float, y:Float):Void {
        if (!initialized) return;
        if (x > 0 && x < 1) return; // God damn touch events!!
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
    
    function onMouseDown(x:Float, y:Float, button:Int):Void {
        if (!initialized) return;
        if (x > 0 && x < 1) return; // God damn touch events!!
        if (invalid) refresh();
        pressHit = getHit(x, y);
        lastX = x;
        lastY = y;
        sendInteraction(pressHit, x, y, MOUSE_DOWN);
    }

    function onMouseUp(x:Float, y:Float, button:Int):Void {
        if (!initialized) return;
        if (x> 0 && x< 1) return; // God damn touch events!!
        if (invalid) refresh();
        var hit:Hit = getHit(x, y);
        lastX = x;
        lastY = y;
        sendInteraction(hit, x, y, MOUSE_UP);
        sendInteraction(pressHit, x, y, hitsEqual(hit, pressHit) ? CLICK : DROP);
        pressHit = NULL_HIT;
    }

    inline function sendInteraction(hit:Hit, x:Float, y:Float, type:MouseInteractionType):Void {
        if (hit.bodyID != null) interact.dispatch(hit.bodyID, hit.glyphID, MOUSE(type, x, y));
    }

    inline function refresh() {
        outputBuffer.resize(width, height);
        if (data == null) data = outputBuffer.createReadbackData();
        updateSignal.dispatch();
        outputBuffer.readBack(outputBuffer, data);
        invalid = false;
    }

    inline function hitsEqual(h1:Hit, h2:Hit):Bool {
        var val:Bool = false;
        if (h1 == null && h2 == null) val = true;
        else if (h1 != null && h2 != null) val = h1.bodyID == h2.bodyID && h1.glyphID == h2.glyphID;
        return val;
    }

}
