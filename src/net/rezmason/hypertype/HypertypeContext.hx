package net.rezmason.hypertype;

import lime.app.Application;
import net.rezmason.gl.GLSystem;
import net.rezmason.hypertype.core.Engine;
import net.rezmason.hypertype.core.FontManager;
import net.rezmason.utils.santa.Santa;
#if debug_graphics import net.rezmason.hypertype.core.DebugGraphics; #end

class HypertypeContext {
    public var engine(default, null):Engine;
    public function new():Void {
        Santa.mapToClass(GLSystem, Singleton(new GLSystem()));
        Santa.mapToClass(FontManager, Singleton(new FontManager(['full', 'matrix'])));

        engine = new Engine();
        Application.current.addModule(engine);
        #if debug_graphics Santa.mapToClass(DebugGraphics, Singleton(engine.debugGraphics)); #end
    }
}
