package net.rezmason.scourge.textview.core;

typedef InteractionSource = {
    var bodyID:Int;
    var glyphID:Int;
}

enum Interaction {
    KEYBOARD(type:KeyboardInteractionType, key:UInt, char:UInt, shift:Bool, alt:Bool, ctrl:Bool);
    MOUSE(type:MouseInteractionType, x:Float, y:Float);
}

enum MouseInteractionType {
    ENTER;
    MOVE;
    EXIT;
    MOUSE_DOWN;
    MOUSE_UP;

    CLICK;
    DROP;

    //WHEEL;
}

enum KeyboardInteractionType {
    KEY_DOWN;
    KEY_REPEAT;
    KEY_UP;
}
