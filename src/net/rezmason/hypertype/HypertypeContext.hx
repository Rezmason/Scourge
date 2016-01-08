package net.rezmason.hypertype;

import lime.app.Application;
import net.rezmason.gl.GLSystem;
import net.rezmason.hypertype.core.DebugDisplay;
import net.rezmason.hypertype.core.Engine;
import net.rezmason.hypertype.core.FontManager;
import net.rezmason.hypertype.core.SceneGraph;
import net.rezmason.utils.santa.Santa;

class HypertypeContext {

    public function new():Void {
        
        Santa.mapToClass(GLSystem, Singleton(new GLSystem()));
        Santa.mapToClass(FontManager, Singleton(new FontManager(['full', 'matrix'])));
        Santa.mapToClass(SceneGraph, Singleton(new SceneGraph()));
        Santa.mapToClass(DebugDisplay, Singleton(new DebugDisplay()));

        var engine = new Engine();
    }
}
