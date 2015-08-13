package net.rezmason.scourge.textview.core;

import lime.ui.KeyCode;
import lime.ui.KeyModifier;

import net.rezmason.scourge.textview.core.Interaction;
import net.rezmason.utils.Zig;
import net.rezmason.utils.santa.Present;

class KeyboardSystem {

    public var interact(default, null):Zig<Null<Int>->Null<Int>->Interaction->Void>;
    public var isAttached(default, null):Bool;
    static var allowedSpecialKeys:Map<KeyCode, Bool> = [
        LEFT => true,
        RIGHT => true,
        UP => true,
        DOWN => true,
    ];

    var keysDown:Map<Int, Bool>;
    var shim:Shim;
    public var focusBodyID:Null<Int>;

    public function new():Void {
        isAttached = false;
        interact = new Zig();
        keysDown = new Map();
        shim = new Present(Shim);
        focusBodyID = null;
    }

    public function attach():Void {
        if (!isAttached) {
            isAttached = true;
            shim.keyDownSignal.add(onKeyDown);
            shim.keyUpSignal.add(onKeyUp);
            // stage.focus = stage;
        }
    }

    public function detach():Void {
        if (isAttached) {
            isAttached = false;
            shim.keyDownSignal.remove(onKeyDown);
            shim.keyUpSignal.remove(onKeyUp);
        }
    }

    function onKeyDown(keyCode:KeyCode, modifier:KeyModifier):Void {
        sendInteraction(keyCode, modifier, keysDown[keyCode] ? KEY_REPEAT : KEY_DOWN);
        keysDown[keyCode] = true;
    }

    function onKeyUp(keyCode:KeyCode, modifier:KeyModifier):Void {
        sendInteraction(keyCode, modifier, KEY_UP);
        keysDown[keyCode] = false;
    }

    inline function sendInteraction(keyCode:KeyCode, modifier:KeyModifier, type:KeyboardInteractionType):Void {
        if (keyCode & 0x40000000 == 0 || allowedSpecialKeys.exists(keyCode)) {
            interact.dispatch(focusBodyID, null, KEYBOARD(type, keyCode, modifier));
        }
    }

}
