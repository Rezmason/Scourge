package net.rezmason.hypertype.core;

import lime.ui.KeyCode;
import lime.ui.KeyModifier;

import net.rezmason.hypertype.core.Interaction;
import net.rezmason.utils.Zig;

class KeyboardSystem {

    static var allowedSpecialKeys:Map<KeyCode, Bool> = [
        LEFT => true,
        RIGHT => true,
        UP => true,
        DOWN => true,
    ];

    public var interactSignal(default, null):Zig<Interaction->Void> = new Zig();
    var keysDown:Map<Int, Bool> = new Map();

    public function new():Void {}

    public function receiveKeyDown(keyCode:KeyCode, modifier:KeyModifier):Void {
        sendInteraction(keyCode, modifier, keysDown[keyCode] ? KEY_REPEAT : KEY_DOWN);
        keysDown[keyCode] = true;
    }

    public function receiveKeyUp(keyCode:KeyCode, modifier:KeyModifier):Void {
        sendInteraction(keyCode, modifier, KEY_UP);
        keysDown[keyCode] = false;
    }

    inline function sendInteraction(keyCode:KeyCode, modifier:KeyModifier, type:KeyboardInteractionType):Void {
        if (keyCode & 0x40000000 == 0 || allowedSpecialKeys.exists(keyCode)) {
            interactSignal.dispatch(KEYBOARD(type, keyCode, modifier));
        }
    }

}
