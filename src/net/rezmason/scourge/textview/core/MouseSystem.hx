package net.rezmason.scourge.textview.core;

import flash.display.BitmapData;
import flash.display.Sprite;
import flash.events.EventDispatcher;
import flash.events.MouseEvent;
import flash.geom.Rectangle;
import flash.geom.Matrix;
import flash.utils.ByteArray;
import flash.Vector;
// import flash.external.ExternalInterface;

import net.rezmason.gl.utils.DrawUtil;
import net.rezmason.gl.OutputBuffer;
import net.rezmason.gl.Types;
import net.rezmason.utils.Zig;

import net.rezmason.scourge.textview.core.Interaction;

class MouseSystem {

    inline static var NULL_ID:Int = -1;

    public var outputBuffer(default, null):OutputBuffer;
    // public var view(get, null):Sprite;
    public var invalid(default, null):Bool;
    public var interact(default, null):Zig<InteractionSource->Interaction->Void>;
    public var updateSignal(default, null):Zig<Void->Void>;
    var data:ReadbackData;
    var bitmapData:BitmapData;
    // var _view:MouseView;

    var hoverRawID:Int;
    var pressRawID:Int;
    var lastMoveEvent:MouseEvent;
    var width:Int;
    var height:Int;
    var drawUtil:DrawUtil;

    public function new(drawUtil:DrawUtil, target:EventDispatcher):Void {
        // _view = new MouseView(0.2, 1);
        // _view = new MouseView(0.2, 40);
        // _view = new MouseView(1.0, 40, 0.5);
        interact = new Zig();
        this.drawUtil = drawUtil;
        updateSignal = new Zig<Void->Void>();

        target.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
        target.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
        target.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
        //target.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);

        hoverRawID = NULL_ID;
        pressRawID = NULL_ID;

        width = -1;
        height = -1;
        invalidate();

        /*
        #if flash
            if (ExternalInterface.available) ExternalInterface.addCallback('externalMouseEvent', onExternalWheel);
        #end
        */

        outputBuffer = drawUtil.createOutputBuffer();
    }

    public function setSize(width:Int, height:Int):Void {
        if (this.width != width || this.height != height) {
            this.width = width;
            this.height = height;

            if (bitmapData != null) bitmapData.dispose();
            bitmapData = null;
            // _view.bitmap.bitmapData = null;
            data = null;

            invalidate();
        }
    }

    public function invalidate():Void invalid = true;

    function getRawID(x:Float, y:Float):Int {

        if (data == null || data.length < width * height * 4) return NULL_ID;

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
                    if (getRawIDFromIndex((row * width + col) * 4 + offset) != rawID) return NULL_ID;
                }
            }
        #end

        // _view.update(x, y, rawID);

        return rawID;
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
            if (data == null) data = drawUtil.createReadbackData(width * height * 4);

            updateSignal.dispatch();
            drawUtil.readBack(outputBuffer, width, height, data);
            // fartBD();

            invalid = false;
        }

        var rawID:Int = getRawID(event.stageX, event.stageY);
        if (rawID == hoverRawID) {
            sendInteraction(rawID, event, MOVE);
        } else {
            sendInteraction(hoverRawID, event, EXIT);
            hoverRawID = rawID;
            sendInteraction(hoverRawID, event, ENTER);
        }

        lastMoveEvent = event;
    }
    /*
    function onMouseWheel(event:MouseEvent):Void {
        sendInteraction(getRawID(event.stageX, event.stageY), event, WHEEL);
    }

    function onExternalWheel(delta:Float):Void {
        if (lastMoveEvent != null) {
            lastMoveEvent.delta = Std.int(delta);
            onMouseWheel(lastMoveEvent);
        }
    }
    */
    function onMouseDown(event:MouseEvent):Void {
        pressRawID = getRawID(event.stageX, event.stageY);
        sendInteraction(pressRawID, event, MOUSE_DOWN);
    }

    function onMouseUp(event:MouseEvent):Void {
        var rawID:Int = getRawID(event.stageX, event.stageY);
        sendInteraction(rawID, event, MOUSE_UP);
        sendInteraction(pressRawID, event, rawID == pressRawID ? CLICK : DROP);
        pressRawID = NULL_ID;
    }

    inline function sendInteraction(rawID:Int, event:MouseEvent, type:MouseInteractionType):Void {
        var bodyID:Int = rawID >> 16 & 0xFF;
        var glyphID:Int = rawID & 0xFFFF;
        if (bodyID >= 0) interact.dispatch({bodyID:bodyID, glyphID:glyphID}, MOUSE(type, event.stageX, event.stageY));
    }

    /*
    function get_view():Sprite {
        return _view;
    }
    */

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
