package net.rezmason.scourge.textview.core;

import flash.display.Stage;
import flash.events.KeyboardEvent;

import net.rezmason.scourge.textview.core.Interaction;

class KeyboardSystem {

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
    }

    public function detach():Void {
        focusBodyID = -1;
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
        var char:Int = event.charCode;
        // trace('$char <${String.fromCharCode(char)}>');
        interact(focusBodyID, -1, KEYBOARD(type, event.keyCode, char, event.shiftKey, event.altKey, event.ctrlKey));
    }

}
