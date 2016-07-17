package net.rezmason.hypertype;

import net.rezmason.hypertype.core.DebugDisplay;
import net.rezmason.hypertype.core.Engine;
import net.rezmason.hypertype.core.FontManager;
import net.rezmason.hypertype.core.Stage;
import net.rezmason.hypertype.core.SystemCalls;
import net.rezmason.utils.santa.Santa;

class HypertypeContext {

    public function new():Void {

        Santa.mapToClass(FontManager, Singleton(new FontManager(['full', 'matrix'])));
        Santa.mapToClass(Stage, Singleton(new Stage()));
        Santa.mapToClass(DebugDisplay, Singleton(new DebugDisplay()));
        Santa.mapToClass(SystemCalls, Singleton(new SystemCalls()));

        var engine = new Engine();
    }
}
