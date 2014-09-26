package net.rezmason.scourge.textview.core;

import flash.display.Stage;
import flash.events.KeyboardEvent;

import net.rezmason.scourge.textview.core.Interaction;
import net.rezmason.utils.Zig;
import net.rezmason.utils.santa.Present;

class KeyboardSystem {

    public var interact(default, null):Zig<Null<Int>->Null<Int>->Interaction->Void>;
    public var isAttached(default, null):Bool;

    #if (!flash && !js)
        var shiftKeyCount:Int;
        var altKeyCount:Int;
        var ctrlKeyCount:Int;
    #end

    var keysDown:Map<Int, Bool>;
    var stage:Stage;
    public var focusBodyID:Null<Int>;

    public function new():Void {
        isAttached = false;
        interact = new Zig();
        keysDown = new Map();
        stage = new Present(Stage);
        focusBodyID = null;

        #if (!flash && !js)
            shiftKeyCount = 0;
            altKeyCount = 0;
            ctrlKeyCount = 0;
        #end
    }

    public function attach():Void {
        if (!isAttached) {
            isAttached = true;
            stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
            stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
            stage.focus = stage;
        }
    }

    public function detach():Void {
        if (isAttached) {
            isAttached = false;
            stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
            stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyUp);
            
            #if (!flash && !js)
                shiftKeyCount = 0;
                altKeyCount = 0;
                ctrlKeyCount = 0;
            #end
        }
    }

    function onKeyDown(event:KeyboardEvent):Void {
        sendInteraction(event, keysDown[event.keyCode] ? KEY_REPEAT : KEY_DOWN);
        keysDown[event.keyCode] = true;
    }

    function onKeyUp(event:KeyboardEvent):Void {
        sendInteraction(event, KEY_UP);
        keysDown[event.keyCode] = false;
    }

    inline function sendInteraction(event:KeyboardEvent, type:KeyboardInteractionType):Void {
        var keyCode:UInt = event.keyCode;
        var charCode:UInt = event.charCode;

        var shiftKey:Bool = event.shiftKey;
        var altKey:Bool = event.altKey;
        var ctrlKey:Bool = event.ctrlKey;

        var ignore:Bool = false;

        #if (!flash && !js)

            if (type != KEY_REPEAT) {
                var val:Int = type == KEY_DOWN ? 1 : -1;
                switch (keyCode) {
                    case 15:
                        ctrlKeyCount  += val;
                        ignore = true;
                    case 16:
                        shiftKeyCount += val;
                        ignore = true;
                    case 17:
                        ctrlKeyCount  += val;
                        ignore = true;
                    case 18:
                        altKeyCount   += val;
                        ignore = true;
                }
            }

            shiftKey = shiftKeyCount > 0;
            ctrlKey = ctrlKeyCount > 0;
            altKey = altKeyCount > 0;
        #end

        // trace(keyCode, charCode, shiftKey, altKey, ctrlKey);

        if (!ignore) interact.dispatch(focusBodyID, null, KEYBOARD(type, keyCode, charCode, shiftKey, altKey, ctrlKey));
    }

}
