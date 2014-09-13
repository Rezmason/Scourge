package net.rezmason.scourge.textview.core;

import flash.display.BitmapData;
import flash.display.Sprite;
import flash.events.EventDispatcher;
import flash.events.MouseEvent;
import flash.geom.Rectangle;
import flash.geom.Matrix;
import flash.utils.ByteArray;
import flash.Vector;

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

class MouseSystem {

    static var NULL_HIT:Hit = {bodyID:null, glyphID:null};

    public var outputBuffer(default, null):ReadbackOutputBuffer;
    // public var view(get, null):Sprite;
    public var invalid(default, null):Bool;
    public var interact(default, null):Zig<Null<Int>->Null<Int>->Interaction->Void>;
    public var updateSignal(default, null):Zig<Void->Void>;
    var data:ReadbackData;
    var bitmapData:BitmapData;
    var rectRegionsByID:Map<Int, Rectangle>;
    var lastRectRegionID:Null<Int>;
    // var _view:MouseView;

    var hoverHit:Hit;
    var pressHit:Hit;
    var lastMoveEvent:MouseEvent;
    var width:Int;
    var height:Int;
    var initialized:Bool;
    var glSys:GLSystem;

    public function new(target:EventDispatcher):Void {
        // _view = new MouseView(0.2, 1);
        // _view = new MouseView(0.2, 40);
        // _view = new MouseView(1.0, 40, 0.5);
        interact = new Zig();
        glSys = new Present(GLSystem);
        updateSignal = new Zig<Void->Void>();
        rectRegionsByID = null;
        lastRectRegionID = null;

        target.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
        target.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
        target.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);

        hoverHit = NULL_HIT;
        pressHit = NULL_HIT;

        width = 0;
        height = 0;
        initialized = false;
        invalidate();

        outputBuffer = glSys.createReadbackOutputBuffer();
    }

    public function setSize(width:Int, height:Int):Void {
        if (!initialized || this.width != width || this.height != height) {
            initialized = true;
            this.width = width;
            this.height = height;

            if (bitmapData != null) bitmapData.dispose();
            bitmapData = null;
            // _view.bitmap.bitmapData = null;
            data = null;

            invalidate();
        }
    }

    public function setRectRegions(rectRegionsByID:Map<Int, Rectangle>):Void {
        this.rectRegionsByID = rectRegionsByID;
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

        // _view.update(x, y, rawID);

        return {bodyID:bodyID, glyphID:glyphID};
    }

    inline function getRawIDFromIndex(index:Int):Int {
        return (data[index] << 16) | (data[index + 1] << 8) | (data[index + 2] << 0);
    }

    /*
    function fartBD():Void {

        var byteArray:ByteArray = #if js new FriendlyByteArray(data) #else data #end ;
        byteArray.position = 0;

        var dupe:BitmapData = bitmapData.clone();
        dupe.setPixels(bitmapData.rect, byteArray);

        var flipMat:Matrix = new Matrix();
        #if js
            flipMat.scale(1, -1);
            flipMat.translate(0, dupe.height);
        #end

        bitmapData.lock();
        bitmapData.fillRect(bitmapData.rect, 0xFF000000);
        bitmapData.draw(dupe, flipMat);
        bitmapData.unlock();
        dupe.dispose();

        _view.bitmap.bitmapData = bitmapData;
    }
    */

    function onMouseMove(event:MouseEvent):Void {

        if (invalid) {
            if (bitmapData == null) {
                bitmapData = new BitmapData(width, height, false, 0xFF00FF);
                // _view.bitmap.bitmapData = bitmapData;
            }

            outputBuffer.resize(width, height);
            if (data == null) data = outputBuffer.createReadbackData();

            updateSignal.dispatch();
            outputBuffer.readBack(outputBuffer, data);
            // fartBD();

            invalid = false;
        }

        var hit:Hit = getHit(event.stageX, event.stageY);
        if (hitsEqual(hit, hoverHit)) {
            sendInteraction(hit, event, MOVE);
        } else {
            sendInteraction(hoverHit, event, EXIT);
            hoverHit = hit;
            sendInteraction(hoverHit, event, ENTER);
        }

        lastMoveEvent = event;
    }
    
    function onMouseDown(event:MouseEvent):Void {
        pressHit = getHit(event.stageX, event.stageY);
        sendInteraction(pressHit, event, MOUSE_DOWN);
    }

    function onMouseUp(event:MouseEvent):Void {
        var hit:Hit = getHit(event.stageX, event.stageY);
        sendInteraction(hit, event, MOUSE_UP);
        sendInteraction(pressHit, event, hitsEqual(hit, pressHit) ? CLICK : DROP);
        pressHit = NULL_HIT;
    }

    inline function sendInteraction(hit:Hit, event:MouseEvent, type:MouseInteractionType):Void {
        if (hit.bodyID != null) {
            var x:Float = event == null ? Math.NaN : event.stageX;
            var y:Float = event == null ? Math.NaN : event.stageY;
            interact.dispatch(hit.bodyID, hit.glyphID, MOUSE(type, x, y));
        }
    }

    /*
    function get_view():Sprite {
        return _view;
    }
    */

    inline function hitsEqual(h1:Hit, h2:Hit):Bool {
        var val:Bool = false;
        if (h1 == null && h2 == null) val = true;
        else if (h1 != null && h2 != null) val = h1.bodyID == h2.bodyID && h1.glyphID == h2.glyphID;
        return val;
    }

}

#if js

    // This is only used for visual debugging, so I'm kind of okay with not including it in OpenFL

    class FriendlyByteArray extends ByteArray {

        public function new(?input:ReadbackData):Void {
            if (input == null) super();
            else setBytes(input);
        }

        public function setBytes(input:ReadbackData):Void {
            byteView = input;
            length = input.length;
            allocated = length;
            this.data = untyped __new__('DataView', input.buffer);
        }
    }
#end
