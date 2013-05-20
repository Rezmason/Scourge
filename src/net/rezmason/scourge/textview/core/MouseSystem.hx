package net.rezmason.scourge.textview.core;

import nme.display.BitmapData;
import nme.display.Sprite;
import nme.events.EventDispatcher;
import nme.events.MouseEvent;
import nme.geom.Rectangle;
import nme.utils.ByteArray;
import nme.Vector;

typedef MouseTarget = {
    var bodyID:Int;
    var glyphID:Int;
    var rawID:Int;
}

class MouseSystem {

    static var NULL_TARGET:MouseTarget = {bodyID:-1, glyphID:-1, rawID:-1};

    public var bitmapData(default, null):BitmapData;
    public var view(get, null):Sprite;
    var _view:MouseView;

    var interact:Int->Int->Interaction->Void;
    var mouseHoverTarget:MouseTarget;
    var mousePressTarget:MouseTarget;
    var pixRect:Rectangle;
    var pixBytes:ByteArray;

    public function new(target:EventDispatcher, interact:Int->Int->Interaction->Void):Void {
        _view = new MouseView(0.2);
        this.interact = interact;

        target.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
        target.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
        target.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);

        mouseHoverTarget = NULL_TARGET;
        mousePressTarget = NULL_TARGET;

        pixRect = new Rectangle(0, 0, 3, 3);
        pixBytes = new ByteArray();
    }

    public function setSize(width:Int, height:Int):Void {
        if (bitmapData != null) bitmapData.dispose();
        bitmapData = new BitmapData(width, height, false, 0x0);
        _view.bitmap.bitmapData = bitmapData;
    }

    function getMouseTarget(x:Float, y:Float):MouseTarget {

        if (bitmapData == null) return NULL_TARGET;

        pixRect.x = Std.int(x) - 1;
        pixRect.y = Std.int(y) - 1;

        pixBytes.position = 0;
        bitmapData.copyPixelsToByteArray(pixRect, pixBytes);
        pixBytes.position = 0;

        var rawID:UInt = pixBytes.readUnsignedInt();
        while (pixBytes.bytesAvailable > 0) if (pixBytes.readUnsignedInt() != rawID) return NULL_TARGET;

        _view.update(x, y, rawID);

        return {
            rawID: rawID,
            bodyID: rawID >> 16 & 0xFF,
            glyphID: rawID & 0xFFFF
        };
    }

    function onMouseMove(event:MouseEvent):Void {
        var target:MouseTarget = getMouseTarget(event.stageX, event.stageY);
        if (target.rawID == mouseHoverTarget.rawID) {
            sendInteraction(target, MOVE);
        } else {
            sendInteraction(mouseHoverTarget, EXIT);
            mouseHoverTarget = target;
            sendInteraction(mouseHoverTarget, ENTER);
        }
    }

    function onMouseDown(event:MouseEvent):Void {
        var target:MouseTarget = getMouseTarget(event.stageX, event.stageY);
        mousePressTarget = target;
        sendInteraction(mousePressTarget, DOWN);
    }

    function onMouseUp(event:MouseEvent):Void {
        var target:MouseTarget = getMouseTarget(event.stageX, event.stageY);
        sendInteraction(target, UP);
        sendInteraction(mousePressTarget, target.rawID == mousePressTarget.rawID ? CLICK : DROP);
        mousePressTarget = null;
    }

    inline function sendInteraction(target:MouseTarget, interaction:Interaction):Void {
        if (target.bodyID >= 0) interact(target.bodyID, target.glyphID, interaction);
    }

    function get_view():Sprite {
        return _view;
    }

}
