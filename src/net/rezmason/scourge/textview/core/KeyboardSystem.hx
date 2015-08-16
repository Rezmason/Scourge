package net.rezmason.scourge.textview.core;

import lime.ui.KeyCode;
import lime.ui.KeyModifier;

import net.rezmason.scourge.textview.core.Interaction;
import net.rezmason.utils.Zig;

class KeyboardSystem {

    static var allowedSpecialKeys:Map<KeyCode, Bool> = [
        LEFT => true,
        RIGHT => true,
        UP => true,
        DOWN => true,
    ];

    public var interactSignal(default, null):Zig<Null<Int>->Null<Int>->Interaction->Void> = new Zig();
    public var active:Bool = false;
    public var focusBodyID:Null<Int> = null;
    var keysDown:Map<Int, Bool> = new Map();

    public function new():Void {}

    public function onKeyDown(keyCode:KeyCode, modifier:KeyModifier):Void {
        if (active) {
            sendInteraction(keyCode, modifier, keysDown[keyCode] ? KEY_REPEAT : KEY_DOWN);
            keysDown[keyCode] = true;
        }
    }

    public function onKeyUp(keyCode:KeyCode, modifier:KeyModifier):Void {
        if (active) {
            sendInteraction(keyCode, modifier, KEY_UP);
            keysDown[keyCode] = false;
        }
    }

    inline function sendInteraction(keyCode:KeyCode, modifier:KeyModifier, type:KeyboardInteractionType):Void {
        if (keyCode & 0x40000000 == 0 || allowedSpecialKeys.exists(keyCode)) {
            interactSignal.dispatch(focusBodyID, null, KEYBOARD(type, keyCode, modifier));
        }
    }

}
