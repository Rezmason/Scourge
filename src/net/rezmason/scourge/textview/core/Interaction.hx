package net.rezmason.scourge.textview.core;

typedef InteractFunction = Int->Int->Interaction->Void;

enum Interaction {
    KEYBOARD(type:KeyboardInteractionType, char:Int);
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
    KEY_UP;
}
