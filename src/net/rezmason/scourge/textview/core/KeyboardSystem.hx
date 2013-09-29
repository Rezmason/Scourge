package net.rezmason.scourge.textview.core;

import flash.display.Stage;
import flash.events.KeyboardEvent;

import net.rezmason.scourge.textview.core.Interaction;

class KeyboardSystem {

    #if (!flash && !js)
        var shiftKeyCount:Int;
        var altKeyCount:Int;
        var ctrlKeyCount:Int;
    #end

    var interact:InteractFunction;
    var keysDown:Map<Int, Bool>;
    var stage:Stage;
    public var focusBodyID:Int;

    public function new(stage:Stage, interact:InteractFunction):Void {
        this.interact = interact;
        keysDown = new Map();
        this.stage = stage;
        stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
        stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
        focusBodyID = -1;

        #if (!flash && !js)
            shiftKeyCount = 0;
            altKeyCount = 0;
            ctrlKeyCount = 0;
        #end
    }

    public function detach():Void {
        focusBodyID = -1;

        #if (!flash && !js)
            shiftKeyCount = 0;
            altKeyCount = 0;
            ctrlKeyCount = 0;
        #end
    }

    public function attach():Void {
        stage.focus = stage;
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
        var keyCode:Int = event.keyCode;
        var charCode:Int = event.charCode;

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

        if (!ignore) interact(focusBodyID, -1, KEYBOARD(type, keyCode, charCode, shiftKey, altKey, ctrlKey));
    }

}
