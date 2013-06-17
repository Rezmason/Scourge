package net.rezmason.scourge.textview.core;

import flash.display.Stage;
import flash.events.KeyboardEvent;

import net.rezmason.scourge.textview.core.Interaction;

class KeyboardSystem {

    var interact:InteractFunction;
    var keysDown:Map<Int, Bool>;
    public var focusBodyID:Int;

    public function new(stage:Stage, interact:InteractFunction):Void {
        this.interact = interact;
        keysDown = new Map();
        stage.focus = stage;
        stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
        stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
        focusBodyID = -1;
    }

    function onKeyDown(event:KeyboardEvent):Void {
        var keyDown:Null<Bool> = keysDown[event.charCode];
        if (keyDown != true) {
            keysDown[event.charCode]  = true;
            sendInteraction(event, KEY_DOWN);
        }
    }

    function onKeyUp(event:KeyboardEvent):Void {
        var keyDown:Null<Bool> = keysDown[event.charCode];
        if (keyDown != false) {
            keysDown[event.charCode]  = false;
            sendInteraction(event, KEY_UP);
        }
    }

    inline function sendInteraction(event:KeyboardEvent, type:KeyboardInteractionType):Void {
        interact(focusBodyID, -1, KEYBOARD(type, event.charCode));
    }

}
