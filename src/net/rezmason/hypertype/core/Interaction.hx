package net.rezmason.hypertype.core;

import lime.ui.KeyCode;
import lime.ui.KeyModifier;

enum Interaction {
    KEYBOARD(type:KeyboardInteractionType, keyCode:KeyCode, modifier:KeyModifier);
    MOUSE(type:MouseInteractionType, x:Float, y:Float);
}
