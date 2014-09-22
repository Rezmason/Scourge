package net.rezmason.scourge.textview.core;

enum Interaction {
    KEYBOARD(type:KeyboardInteractionType, key:UInt, char:UInt, shift:Bool, alt:Bool, ctrl:Bool);
    MOUSE(type:MouseInteractionType, x:Float, y:Float);
}
