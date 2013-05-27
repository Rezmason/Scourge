package net.rezmason.scourge.textview.core;

import flash.display.BitmapData;
import flash.display.Sprite;
import flash.events.EventDispatcher;
import flash.events.MouseEvent;
import flash.geom.Rectangle;
import flash.utils.ByteArray;
import flash.Vector;
import flash.external.ExternalInterface;

typedef InteractFunction = Int->Int->Interaction->Float->Float/*->Float*/->Void;

class MouseSystem {

    inline static var NULL_ID:Int = -1;

    public var bitmapData(default, null):BitmapData;
    public var view(get, null):Sprite;
    var _view:MouseView;

    var interact:InteractFunction;
    var hoverRawID:Int;
    var pressRawID:Int;
    var pixRect:Rectangle;
    var pixBytes:ByteArray;
    var lastMoveEvent:MouseEvent;

    public function new(target:EventDispatcher, interact:InteractFunction):Void {
        _view = new MouseView(0.2, 40);
        // _view = new MouseView(1.0, 40, 0.5);
        this.interact = interact;

        target.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
        target.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
        target.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
        //target.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);

        hoverRawID = NULL_ID;
        pressRawID = NULL_ID;

        pixRect = new Rectangle(0, 0, 3, 3);
        pixBytes = new ByteArray();

        /*
        #if flash
            if (ExternalInterface.available) ExternalInterface.addCallback('externalMouseEvent', onExternalWheel);
        #end
        */
    }

    public function setSize(width:Int, height:Int):Void {
        if (bitmapData != null) bitmapData.dispose();
        bitmapData = new BitmapData(width, height, false, 0x0);
        _view.bitmap.bitmapData = bitmapData;
    }

    function getRawID(x:Float, y:Float):Int {

        if (bitmapData == null) return NULL_ID;

        pixRect.x = Std.int(x) - 1;
        pixRect.y = Std.int(y) - 1;

        pixBytes.position = 0;
        bitmapData.copyPixelsToByteArray(pixRect, pixBytes);
        pixBytes.position = 0;

        var rawID:UInt = pixBytes.readUnsignedInt();
        while (pixBytes.bytesAvailable > 0) if (pixBytes.readUnsignedInt() != rawID) return NULL_ID;

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
