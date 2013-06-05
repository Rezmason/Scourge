package net.rezmason.scourge.textview.core;

import flash.display.BitmapData;
import flash.display.Sprite;
import flash.events.EventDispatcher;
import flash.events.MouseEvent;
import flash.geom.Rectangle;
import flash.geom.Matrix;
import flash.utils.ByteArray;
import flash.Vector;
import flash.external.ExternalInterface;

import net.rezmason.gl.utils.DrawUtil;
import net.rezmason.gl.OutputBuffer;
import net.rezmason.gl.Types;

typedef InteractFunction = Int->Int->Interaction->Float->Float/*->Float*/->Void;

class MouseSystem {

    inline static var NULL_ID:Int = -1;

    public var outputBuffer(default, null):OutputBuffer;
    public var view(get, null):Sprite;
    var data:ReadbackData;
    var bitmapData:BitmapData;
    var _view:MouseView;

    var interact:InteractFunction;
    var hoverRawID:Int;
    var pressRawID:Int;
    var lastMoveEvent:MouseEvent;
    var width:Int;
    var height:Int;
    var drawUtil:DrawUtil;

    public function new(drawUtil:DrawUtil, target:EventDispatcher, interact:InteractFunction):Void {
        _view = new MouseView(0.2, 40);
        // _view = new MouseView(1.0, 40, 0.5);
        this.interact = interact;
        this.drawUtil = drawUtil;

        target.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
        target.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
        target.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
        //target.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);

        hoverRawID = NULL_ID;
        pressRawID = NULL_ID;

        width = -1;
        height = -1;

        /*
        #if flash
            if (ExternalInterface.available) ExternalInterface.addCallback('externalMouseEvent', onExternalWheel);
        #end
        */

        outputBuffer = drawUtil.createOutputBuffer();
    }

    public function fartBD():Void {

        return;

        var byteArray:ByteArray;
        #if js
            byteArray = new FriendlyByteArray(data);
        #else
            byteArray = data;
        #end
        byteArray.position = 0;

        var dupe:BitmapData = bitmapData.clone();
        dupe.setPixels(bitmapData.rect, byteArray);

        var flipMat:Matrix = new Matrix();
        flipMat.scale(1, -1);
        flipMat.translate(0, dupe.height);

        bitmapData.draw(dupe, flipMat);

        _view.bitmap.bitmapData = bitmapData;
    }

    public function setSize(width:Int, height:Int):Void {
        if (bitmapData != null) bitmapData.dispose();
        bitmapData = new BitmapData(width, height, false, 0xFF00FF);
        _view.bitmap.bitmapData = bitmapData;

        outputBuffer.resize(width, height);

        if (this.width != width || this.height != height) {
            this.width = width;
            this.height = height;

            data = new ReadbackData(width * height * 4);
        }

        fartBD();
    }

    public function readOutputBuffer():Void {
        drawUtil.readBack(outputBuffer, width, height, data);
        fartBD();
    }

    function getRawID(x:Float, y:Float):Int {

        if (data == null) return NULL_ID;

        var rectLeft:Int = Std.int(x) - 1;
        var rectTop:Int = Std.int(height - y) - 1;
        var index:Int = (rectTop * width + rectLeft) * 4;

        var idElements:Array<Int> = [
            data[index + 0],
            data[index + 1],
            data[index + 2],
            data[index + 3],
        ];

        var rawID:Int = (idElements[0] << 16) | (idElements[1] << 8) | (idElements[2] << 0);

        /*
        for (row in 0...3) {
            for (col in 0...3) {
                index = (row * width + col) * 4;
                for (el in 0...4) if (idElements[el] != data[index + el]) return NULL_ID;
            }
        }
        */

        _view.update(x, y, rawID);

        return rawID;
    }

    function onMouseMove(event:MouseEvent):Void {
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
        sendInteraction(pressRawID, event, DOWN);
    }

    function onMouseUp(event:MouseEvent):Void {
        var rawID:Int = getRawID(event.stageX, event.stageY);
        sendInteraction(rawID, event, UP);
        sendInteraction(pressRawID, event, rawID == pressRawID ? CLICK : DROP);
        pressRawID = NULL_ID;
    }

    inline function sendInteraction(rawID:Int, event:MouseEvent, interaction:Interaction):Void {
        var bodyID:Int = rawID >> 16 & 0xFF;
        var glyphID:Int = rawID & 0xFFFF;
        if (bodyID >= 0) interact(bodyID, glyphID, interaction, event.stageX, event.stageY/*, event.delta*/);
    }

    function get_view():Sprite {
        return _view;
    }

}

#if js
    class FriendlyByteArray extends ByteArray {

        public function new(?input:ReadbackData):Void {
            if (input == null) super();
            else setBytes(input);
        }

        public function setBytes(input:ReadbackData):Void {
            byteView = input;
            length = input.length;
            allocated = length;
            this.data = untyped __new__("DataView", input.buffer);
        }
    }
#end
